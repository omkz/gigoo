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
end
