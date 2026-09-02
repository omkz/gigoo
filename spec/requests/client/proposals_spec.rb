require "rails_helper"

RSpec.describe "Client proposals", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "redirects an unauthenticated user to sign in" do
    job = create(:job)

    get client_job_proposals_path(job)

    expect(response).to redirect_to(new_session_path)
  end

  it "allows the owner to view proposal details and freelancer context" do
    job = create(:job)
    proposal = create(:proposal, job: job, status: :pending, message: "My detailed delivery plan.")
    profile = proposal.freelancer.freelancer_profile
    sign_in(job.client)

    get client_job_proposals_path(job)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(job.title, job.status, "$5,000.00")
    expect(response.body).to include(proposal.freelancer.name)
    expect(response.body).not_to include(proposal.freelancer.email_address)
    expect(response.body).to include(profile.title, profile.location, profile.skills.first)
    expect(response.body).to include("$4,500.00", proposal.message, proposal.status)
    expect(response.body).to include("Accept proposal")
  end

  it "orders proposals newest first" do
    job = create(:job)
    older = create(:proposal, job: job, message: "Older proposal", created_at: 2.days.ago)
    newer = create(:proposal, job: job, message: "Newer proposal", created_at: 1.hour.ago)
    sign_in(job.client)

    get client_job_proposals_path(job)

    expect(response.body.index(newer.message)).to be < response.body.index(older.message)
  end

  it "shows an empty state when the job has no proposals" do
    job = create(:job, status: :draft)
    sign_in(job.client)

    get client_job_proposals_path(job)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No proposals yet.")
  end

  it "does not expose freelancer drafts to the client" do
    draft = create(:proposal, status: :draft, message: "Private unfinished cover letter")
    sign_in(draft.job.client)

    get client_job_proposals_path(draft.job)

    expect(response.body).to include("No proposals yet.")
    expect(response.body).not_to include(draft.message, draft.freelancer.name)
  end

  it "does not allow an owner without a client profile to access proposals" do
    job = create(:job)
    job.client.client_profile.destroy!
    sign_in(job.client)

    get client_job_proposals_path(job)

    expect(response).to have_http_status(:forbidden)
  end

  it "does not allow another client to view a job's proposals" do
    job = create(:job)
    other_client = create(:client_profile).user
    sign_in(other_client)

    get client_job_proposals_path(job)

    expect(response).to have_http_status(:forbidden)
  end

  %i[ support admin ].each do |role|
    it "does not give #{role} automatic access to another client's proposals" do
      job = create(:job)
      privileged_user = create(:user, role: role)
      create(:client_profile, user: privileged_user)
      sign_in(privileged_user)

      get client_job_proposals_path(job)

      expect(response).to have_http_status(:forbidden)
    end
  end

  it "isolates proposals to the selected owned job" do
    owner = create(:client_profile).user
    selected_job = create(:job, client: owner)
    other_owned_job = create(:job, client: owner)
    another_client_job = create(:job)
    visible = create(:proposal, job: selected_job, message: "Visible proposal")
    hidden_owned = create(:proposal, job: other_owned_job, message: "Other owned job proposal")
    hidden_client = create(:proposal, job: another_client_job, message: "Another client proposal")
    sign_in(owner)

    get client_job_proposals_path(selected_job)

    expect(response.body).to include(visible.message)
    expect(response.body).not_to include(hidden_owned.message)
    expect(response.body).not_to include(hidden_client.message)
  end

  describe "accepting a proposal" do
    it "redirects an unauthenticated user to sign in" do
      proposal = create(:proposal)

      patch accept_client_job_proposal_path(proposal.job, proposal)

      expect(response).to redirect_to(new_session_path)
      expect(proposal.reload).to be_pending
    end

    it "atomically accepts the proposal, creates a contract, rejects other pending proposals, and closes the job" do
      proposal = create(:proposal, amount_cents: 475_000)
      other_pending = create(:proposal, job: proposal.job)
      withdrawn = create(:proposal, job: proposal.job, status: :withdrawn)
      sign_in(proposal.job.client)

      expect do
        patch accept_client_job_proposal_path(proposal.job, proposal)
      end.to change(Contract, :count).by(1)

      contract = proposal.job.reload.contract
      expect(proposal.reload).to be_accepted
      expect(other_pending.reload).to be_rejected
      expect(withdrawn.reload).to be_withdrawn
      expect(proposal.job).to be_closed
      expect(contract.client).to eq(proposal.job.client)
      expect(contract.freelancer).to eq(proposal.freelancer)
      expect(contract.amount_cents).to eq(proposal.amount_cents)
      expect(contract).to be_active
      expect(contract.started_at).to be_present
      expect(response).to redirect_to(client_contract_path(contract))

      get client_job_proposals_path(proposal.job)
      expect(response.body).to include("View contract", "Contract active", "accepted", "rejected")
      expect(response.body).not_to include("Accept proposal")
    end

    it "derives all contract attributes from the job and proposal" do
      proposal = create(:proposal, amount_cents: 325_000)
      spoofed_client = create(:client_profile).user
      spoofed_freelancer = create(:freelancer_profile).user
      sign_in(proposal.job.client)

      patch accept_client_job_proposal_path(proposal.job, proposal), params: {
        amount_cents: 1,
        client_id: spoofed_client.id,
        freelancer_id: spoofed_freelancer.id,
        status: :cancelled,
        contract_id: 123
      }

      contract = proposal.job.reload.contract
      expect(contract.client).to eq(proposal.job.client)
      expect(contract.freelancer).to eq(proposal.freelancer)
      expect(contract.amount_cents).to eq(325_000)
      expect(contract).to be_active
      expect(proposal.reload).to be_accepted
    end

    it "forbids another client" do
      proposal = create(:proposal)
      sign_in(create(:client_profile).user)

      expect do
        patch accept_client_job_proposal_path(proposal.job, proposal)
      end.not_to change(Contract, :count)

      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload).to be_pending
    end

    it "forbids an owner without a client profile" do
      proposal = create(:proposal)
      proposal.job.client.client_profile.destroy!
      sign_in(proposal.job.client)

      patch accept_client_job_proposal_path(proposal.job, proposal)

      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload).to be_pending
    end

    %i[ support admin ].each do |role|
      it "does not give #{role} an ownership bypass" do
        proposal = create(:proposal)
        privileged_user = create(:user, role: role)
        create(:client_profile, user: privileged_user)
        sign_in(privileged_user)

        patch accept_client_job_proposal_path(proposal.job, proposal)

        expect(response).to have_http_status(:forbidden)
        expect(proposal.reload).to be_pending
      end
    end

    it "does not find a proposal from another job through the nested URL" do
      owned_job = create(:job)
      other_proposal = create(:proposal)
      sign_in(owned_job.client)

      patch accept_client_job_proposal_path(owned_job, other_proposal)

      expect(response).to have_http_status(:not_found)
      expect(other_proposal.reload).to be_pending
    end

    %i[ draft closed ].each do |status|
      it "does not accept a proposal for a #{status} job" do
        proposal = create(:proposal)
        proposal.job.update!(status: status)
        sign_in(proposal.job.client)

        patch accept_client_job_proposal_path(proposal.job, proposal)

        expect(response).to have_http_status(:forbidden)
        expect(proposal.reload).to be_pending
        expect(proposal.job.reload.contract).to be_nil
      end
    end

    %i[ rejected withdrawn ].each do |status|
      it "does not accept a #{status} proposal" do
        proposal = create(:proposal, status: status)
        sign_in(proposal.job.client)

        patch accept_client_job_proposal_path(proposal.job, proposal)

        expect(response).to have_http_status(:forbidden)
        expect(proposal.reload.status).to eq(status.to_s)
        expect(proposal.job.contract).to be_nil
      end
    end

    it "does not accept an already accepted proposal twice" do
      proposal = create(:proposal)
      sign_in(proposal.job.client)

      patch accept_client_job_proposal_path(proposal.job, proposal)
      contract = proposal.job.reload.contract

      expect do
        patch accept_client_job_proposal_path(proposal.job, proposal)
      end.not_to change(Contract, :count)
      expect(response).to have_http_status(:forbidden)
      expect(proposal.job.reload.contract).to eq(contract)
    end

    it "does not accept when the job already has a contract" do
      proposal = create(:proposal)
      existing_contract = create(:contract, job: proposal.job)
      sign_in(proposal.job.client)

      patch accept_client_job_proposal_path(proposal.job, proposal)

      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload).to be_pending
      expect(proposal.job.reload.contract).to eq(existing_contract)
    end

    it "rolls back every state change when contract creation fails" do
      proposal = create(:proposal)
      other_pending = create(:proposal, job: proposal.job)
      sign_in(proposal.job.client)
      allow(Contract).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Contract.new))

      expect do
        patch accept_client_job_proposal_path(proposal.job, proposal)
      end.not_to change(Contract, :count)

      expect(response).to redirect_to(client_job_proposals_path(proposal.job))
      expect(proposal.reload).to be_pending
      expect(other_pending.reload).to be_pending
      expect(proposal.job.reload).to be_open
    end
  end
end
