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
    expect(response.body).to include(proposal.freelancer.email_address)
    expect(response.body).to include(profile.title, profile.location, profile.skills.first)
    expect(response.body).to include("$4,500.00", proposal.message, proposal.status)
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
end
