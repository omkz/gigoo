require "rails_helper"

RSpec.describe "Client jobs", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  def client_user
    create(:client_profile).user
  end

  let(:valid_job_params) do
    {
      title: "Build a reporting dashboard",
      description: "Create a useful dashboard for our operations team.",
      budget: "1250.50",
      skills: "Ruby, Rails, PostgreSQL"
    }
  end

  it "shows a client-profile user only their posted jobs" do
    user = client_user
    own_job = create(:job, client: user, title: "My private listing")
    other_job = create(:job, title: "Another client's listing")
    sign_in(user)

    get client_jobs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(own_job.title)
    expect(response.body).not_to include(other_job.title)
  end

  it "shows each owned job's proposal count and link" do
    user = client_user
    job_with_proposals = create(:job, client: user, title: "Popular job")
    job_without_proposals = create(:job, client: user, title: "New job")
    create(:proposal, job: job_with_proposals)
    create(:proposal, job: job_with_proposals)
    sign_in(user)

    get client_jobs_path

    expect(response.body).to include(client_job_proposals_path(job_with_proposals), "View proposals (2)")
    expect(response.body).to include(client_job_proposals_path(job_without_proposals), "View proposals (0)")
  end

  it "does not count proposal drafts as received proposals" do
    job = create(:job)
    create(:proposal, job: job, status: :draft)
    sign_in(job.client)

    get client_jobs_path

    expect(response.body).to include(client_job_proposals_path(job), "View proposals (0)")
  end

  it "shows each owned job's shortlist count and link" do
    user = client_user
    shortlisted_job = create(:job, client: user, title: "Shortlisted job")
    empty_job = create(:job, client: user, title: "Empty shortlist job")
    create(:shortlist, job: shortlisted_job, client: user)
    create(:shortlist, job: shortlisted_job, client: user)
    sign_in(user)

    get client_jobs_path

    expect(response.body).to include(client_job_shortlists_path(shortlisted_job), "Shortlist (2)")
    expect(response.body).to include(client_job_shortlists_path(empty_job), "Shortlist (0)")
    expect(response.body).to include("job_#{shortlisted_job.id}_shortlist_link", "job_#{empty_job.id}_shortlist_link")
  end

  it "allows a client-profile user to create a draft job" do
    user = client_user
    sign_in(user)

    expect do
      post client_jobs_path, params: { job: valid_job_params }
    end.to change(user.posted_jobs, :count).by(1)

    job = user.posted_jobs.order(:created_at).last
    expect(job).to be_draft
    expect(job.budget_cents).to eq(125_050)
    expect(job.skills).to eq([ "Ruby", "Rails", "PostgreSQL" ])
    expect(response).to redirect_to(client_jobs_path)
  end

  it "always derives the client from the authenticated user" do
    user = client_user
    another_client = client_user
    sign_in(user)

    post client_jobs_path, params: { job: valid_job_params.merge(client_id: another_client.id) }

    expect(Job.order(:created_at).last.client).to eq(user)
  end

  it "does not allow a user without a client profile to create a job" do
    sign_in(create(:user))

    expect do
      post client_jobs_path, params: { job: valid_job_params }
    end.not_to change(Job, :count)

    expect(response).to have_http_status(:forbidden)
  end

  it "does not allow a user to edit another client's job" do
    owner = client_user
    other_client = client_user
    job = create(:job, client: owner)
    sign_in(other_client)

    get edit_client_job_path(job)

    expect(response).to have_http_status(:forbidden)
  end

  it "allows the owner to edit their job" do
    owner = client_user
    job = create(:job, client: owner)
    sign_in(owner)

    patch client_job_path(job), params: {
      job: valid_job_params.merge(title: "Updated dashboard", skills: "Rails, Hotwire")
    }

    expect(response).to redirect_to(client_jobs_path)
    expect(job.reload.title).to eq("Updated dashboard")
    expect(job.skills).to eq([ "Rails", "Hotwire" ])
  end

  it "allows the owner to publish a draft job" do
    owner = client_user
    job = create(:job, client: owner, status: :draft)
    sign_in(owner)

    patch publish_client_job_path(job)

    expect(response).to redirect_to(client_jobs_path)
    expect(job.reload).to be_open
  end

  it "allows the owner to close an open job" do
    owner = client_user
    job = create(:job, client: owner, status: :open)
    sign_in(owner)

    patch close_client_job_path(job)

    expect(response).to redirect_to(client_jobs_path)
    expect(job.reload).to be_closed
  end

  it "renders validation errors for invalid input" do
    user = client_user
    sign_in(user)

    expect do
      post client_jobs_path, params: { job: valid_job_params.merge(title: "", budget: "-1") }
    end.not_to change(Job, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("prevented this job from being saved")
  end

  it "requires client capability to view My Jobs" do
    sign_in(create(:user))

    get client_jobs_path

    expect(response).to have_http_status(:forbidden)
  end

  it "keeps the normal management actions for a job without a contract" do
    job = create(:job, status: :open)
    sign_in(job.client)

    get client_jobs_path

    expect(response.body).to include(edit_client_job_path(job))
    expect(response.body).to include(close_client_job_path(job))
    expect(response.body).not_to include("View contract")
  end

  it "shows a View contract action and Active status for a job with an active contract" do
    contract = create(:contract, status: :active)
    job = contract.job
    sign_in(job.client)

    get client_jobs_path

    expect(response.body).to include(client_contract_path(contract), "View contract")
    expect(response.body).to include("Contract: Active")
  end

  it "shows Completed status for a job with a completed contract" do
    contract = create(:contract, :completed)
    job = contract.job
    sign_in(job.client)

    get client_jobs_path

    expect(response.body).to include(client_contract_path(contract), "View contract")
    expect(response.body).to include("Contract: Completed")
  end

  it "does not show Edit, Publish, or Close for a job that already has a contract" do
    contract = create(:contract)
    job = contract.job
    sign_in(job.client)

    get client_jobs_path

    expect(response.body).not_to include(edit_client_job_path(job))
    expect(response.body).not_to include(publish_client_job_path(job))
    expect(response.body).not_to include(close_client_job_path(job))
    expect(response.body).not_to include("Publish")
    expect(response.body).not_to include(">Close<")
  end

  it "does not present a job with a contract as still open for hiring" do
    contract = create(:contract)
    job = contract.job
    sign_in(job.client)

    get client_jobs_path

    expect(response.body).not_to include("View proposals (")
    expect(response.body).not_to include("Accept proposal")
    expect(response.body).to include("View proposal history")
  end

  it "exposes the newly created contract in My Jobs after a proposal is accepted" do
    job = create(:job, status: :open)
    proposal = create(:proposal, job: job)
    sign_in(job.client)

    patch accept_client_job_proposal_path(job, proposal)
    contract = job.reload.contract
    expect(contract).to be_present

    get client_jobs_path

    expect(response.body).to include(client_contract_path(contract), "View contract", "Contract: Active")
  end

  it "reflects contract completion in My Jobs without creating another contract" do
    contract = create(:contract, status: :active)
    job = contract.job
    sign_in(job.client)

    patch complete_client_contract_path(contract)

    get client_jobs_path

    expect(Contract.where(job: job).count).to eq(1)
    expect(response.body).to include("Contract: Completed")
  end

  it "eager loads contracts on My Jobs to avoid N+1 queries" do
    user = client_user
    5.times { create(:contract, job: create(:job, client: user, status: :closed)) }
    3.times { create(:job, client: user, status: :open) }
    sign_in(user)

    queries = []
    callback = ->(*, started, finished, unique_id, payload) {
      queries << payload[:sql] if payload[:sql].match?(/\ASELECT/i) && payload[:name] != "SCHEMA"
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get client_jobs_path
    end

    contract_queries = queries.select { |sql| sql.include?('"contracts"') }
    expect(contract_queries.length).to be <= 1
  end
end
