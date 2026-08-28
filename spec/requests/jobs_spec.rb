require "rails_helper"

RSpec.describe "Public jobs", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "allows an unauthenticated visitor to browse only open jobs" do
    open_job = create(:job, status: :open, title: "Visible open job")
    draft_job = create(:job, status: :draft, title: "Hidden draft job")
    closed_job = create(:job, status: :closed, title: "Hidden closed job")

    get jobs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(open_job.title)
    expect(response.body).not_to include(draft_job.title)
    expect(response.body).not_to include(closed_job.title)
  end

  it "shows newest open jobs first" do
    older_job = create(:job, status: :open, title: "Older job", created_at: 2.days.ago)
    newer_job = create(:job, status: :open, title: "Newer job", created_at: 1.hour.ago)

    get jobs_path

    expect(response.body.index(newer_job.title)).to be < response.body.index(older_job.title)
  end

  it "allows an unauthenticated visitor to view an open job" do
    job = create(:job, status: :open)

    get job_path(job)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(job.title, job.description, "Sign in to submit")
  end

  it "does not expose a draft job detail" do
    job = create(:job, status: :draft)

    get job_path(job)

    expect(response).to have_http_status(:not_found)
  end

  it "does not expose a closed job detail" do
    job = create(:job, status: :closed)

    get job_path(job)

    expect(response).to have_http_status(:not_found)
  end

  it "prompts an authenticated user without a freelancer profile to create one" do
    sign_in(create(:user))

    get job_path(create(:job, status: :open))

    expect(response.body).to include("Create a freelancer profile to submit a proposal.")
    expect(response.body).not_to include("proposal[amount]")
  end

  it "shows the proposal form to an eligible freelancer" do
    sign_in(create(:freelancer_profile).user)

    get job_path(create(:job, status: :open))

    expect(response.body).to include("Submit proposal")
    expect(response.body).to include("proposal[amount]", "proposal[message]")
  end

  it "shows the existing proposal status instead of another form" do
    proposal = create(:proposal, status: :pending)
    sign_in(proposal.freelancer)

    get job_path(proposal.job)

    expect(response.body).to include("Proposal submitted · Pending")
    expect(response.body).not_to include("proposal[amount]")
  end
end
