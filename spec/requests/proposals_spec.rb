require "rails_helper"

RSpec.describe "Proposals", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  def freelancer_user
    create(:freelancer_profile).user
  end

  let(:job) { create(:job, status: :open) }
  let(:valid_proposal_params) do
    { amount: "975.25", message: "I can deliver this project on schedule." }
  end

  it "lets a freelancer-profile user submit a pending proposal with a normal amount" do
    freelancer = freelancer_user
    sign_in(freelancer)

    expect do
      post job_proposals_path(job), params: { proposal: valid_proposal_params }
    end.to change(job.proposals, :count).by(1)

    proposal = job.proposals.last
    expect(proposal.freelancer).to eq(freelancer)
    expect(proposal).to be_pending
    expect(proposal.amount_cents).to eq(97_525)
    expect(response).to redirect_to(job_path(job))
  end

  it "does not allow proposal identity or status to be spoofed" do
    freelancer = freelancer_user
    spoofed_freelancer = freelancer_user
    original_client = job.client
    sign_in(freelancer)

    post job_proposals_path(job), params: {
      proposal: valid_proposal_params.merge(
        freelancer_id: spoofed_freelancer.id,
        client_id: spoofed_freelancer.id,
        status: :accepted
      )
    }

    proposal = job.proposals.last
    expect(proposal.freelancer).to eq(freelancer)
    expect(proposal).to be_pending
    expect(job.reload.client).to eq(original_client)
  end

  it "does not allow a user without a freelancer profile to submit" do
    sign_in(create(:user))

    expect do
      post job_proposals_path(job), params: { proposal: valid_proposal_params }
    end.not_to change(Proposal, :count)

    expect(response).to have_http_status(:forbidden)
  end

  it "does not allow a freelancer to propose to their own job" do
    create(:freelancer_profile, user: job.client)
    sign_in(job.client)

    expect do
      post job_proposals_path(job), params: { proposal: valid_proposal_params }
    end.not_to change(Proposal, :count)

    expect(response).to have_http_status(:forbidden)
  end

  it "does not allow a proposal to a draft job" do
    draft_job = create(:job, status: :draft)
    sign_in(freelancer_user)

    expect do
      post job_proposals_path(draft_job), params: { proposal: valid_proposal_params }
    end.not_to change(Proposal, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not allow a proposal to a closed job" do
    closed_job = create(:job, status: :closed)
    sign_in(freelancer_user)

    expect do
      post job_proposals_path(closed_job), params: { proposal: valid_proposal_params }
    end.not_to change(Proposal, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not allow a duplicate proposal" do
    freelancer = freelancer_user
    create(:proposal, job: job, freelancer: freelancer)
    sign_in(freelancer)

    expect do
      post job_proposals_path(job), params: { proposal: valid_proposal_params }
    end.not_to change(Proposal, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Freelancer has already been taken")
  end

  it "renders useful validation errors for invalid proposal input" do
    sign_in(freelancer_user)

    expect do
      post job_proposals_path(job), params: { proposal: { amount: "0", message: "" } }
    end.not_to change(Proposal, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("prevented this proposal from being submitted")
    expect(response.body).to include("Message can&#39;t be blank")
  end
end
