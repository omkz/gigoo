require "rails_helper"

RSpec.describe "Client shortlists", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "redirects an unauthenticated user to sign in" do
    job = create(:job)
    profile = create(:freelancer_profile)

    post client_job_shortlists_path(job), params: { freelancer_profile_id: profile.id }

    expect(response).to redirect_to(new_session_path)
  end

  it "allows an owning client to shortlist a freelancer" do
    job = create(:job)
    profile = create(:freelancer_profile)
    sign_in(job.client)

    expect do
      post client_job_shortlists_path(job), params: { freelancer_profile_id: profile.id }
    end.to change(job.shortlists, :count).by(1)

    shortlist = job.shortlists.last
    expect(shortlist.client).to eq(job.client)
    expect(shortlist.freelancer).to eq(profile.user)
    expect(response).to redirect_to(freelancer_path(profile))
  end

  it "derives client and job from the authenticated user and nested route" do
    job = create(:job)
    another_job = create(:job)
    profile = create(:freelancer_profile)
    spoofed_client = create(:client_profile).user
    sign_in(job.client)

    post client_job_shortlists_path(job), params: {
      freelancer_profile_id: profile.id,
      client_id: spoofed_client.id,
      freelancer_id: spoofed_client.id,
      job_id: another_job.id
    }

    shortlist = Shortlist.order(:created_at).last
    expect(shortlist.client).to eq(job.client)
    expect(shortlist.job).to eq(job)
    expect(shortlist.freelancer).to eq(profile.user)
  end

  it "does not allow a client to shortlist for another client's job" do
    job = create(:job)
    profile = create(:freelancer_profile)
    sign_in(create(:client_profile).user)

    expect do
      post client_job_shortlists_path(job), params: { freelancer_profile_id: profile.id }
    end.not_to change(Shortlist, :count)

    expect(response).to have_http_status(:forbidden)
  end

  it "does not allow a client to shortlist themselves" do
    job = create(:job)
    profile = create(:freelancer_profile, user: job.client)
    sign_in(job.client)

    expect do
      post client_job_shortlists_path(job), params: { freelancer_profile_id: profile.id }
    end.not_to change(Shortlist, :count)

    expect(response).to have_http_status(:forbidden)
  end

  it "does not accept a user without a legitimate freelancer profile" do
    job = create(:job)
    user_without_profile = create(:user)
    sign_in(job.client)

    expect do
      post client_job_shortlists_path(job), params: {
        freelancer_profile_id: 0,
        freelancer_id: user_without_profile.id
      }
    end.not_to change(Shortlist, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "handles a duplicate shortlist entry gracefully" do
    shortlist = create(:shortlist)
    profile = shortlist.freelancer.freelancer_profile
    sign_in(shortlist.client)

    expect do
      post client_job_shortlists_path(shortlist.job), params: { freelancer_profile_id: profile.id }
    end.not_to change(Shortlist, :count)

    expect(response).to redirect_to(freelancer_path(profile))
    follow_redirect!
    expect(response.body).to include("Freelancer has already been taken")
  end

  it "does not allow a user without a client profile to shortlist" do
    job = create(:job)
    profile = create(:freelancer_profile)
    sign_in(create(:user))

    expect do
      post client_job_shortlists_path(job), params: { freelancer_profile_id: profile.id }
    end.not_to change(Shortlist, :count)

    expect(response).to have_http_status(:forbidden)
  end

  it "allows the owner to view only the selected job's shortlist with profile details" do
    owner = create(:client_profile).user
    selected_job = create(:job, client: owner)
    other_job = create(:job, client: owner)
    visible_profile = create(:freelancer_profile, title: "Visible candidate")
    hidden_profile = create(:freelancer_profile, title: "Hidden candidate")
    visible = create(:shortlist, job: selected_job, client: owner, freelancer: visible_profile.user)
    create(:shortlist, job: other_job, client: owner, freelancer: hidden_profile.user)
    profile = visible.freelancer.freelancer_profile
    sign_in(owner)

    get client_job_shortlists_path(selected_job)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.user.name, profile.title, profile.location, profile.skills.first, "$250.00/hr")
    expect(response.body).not_to include(profile.user.email_address)
    expect(response.body).to include(freelancer_path(profile))
    expect(response.body).not_to include(hidden_profile.title)
  end

  it "orders shortlist entries newest first" do
    job = create(:job)
    older_profile = create(:freelancer_profile, title: "Older candidate")
    newer_profile = create(:freelancer_profile, title: "Newer candidate")
    older = create(:shortlist, job: job, client: job.client, freelancer: older_profile.user, created_at: 2.days.ago)
    newer = create(:shortlist, job: job, client: job.client, freelancer: newer_profile.user, created_at: 1.hour.ago)
    sign_in(job.client)

    get client_job_shortlists_path(job)

    older_title = older.freelancer.freelancer_profile.title
    newer_title = newer.freelancer.freelancer_profile.title
    expect(response.body.index(newer_title)).to be < response.body.index(older_title)
  end

  it "shows role-scoped trust evidence for each shortlisted freelancer" do
    job = create(:job)
    strong_profile = create(:freelancer_profile, title: "Strong candidate")
    create(:client_profile, user: strong_profile.user)
    mixed_profile = create(:freelancer_profile, title: "Mixed candidate")
    repeat_client = create(:client_profile).user

    first_contract = create(:contract, :completed, job: create(:job, client: repeat_client), client: repeat_client, freelancer: strong_profile.user)
    second_contract = create(:contract, :completed, job: create(:job, client: repeat_client), client: repeat_client, freelancer: strong_profile.user)
    create(:review, contract: first_contract, reviewer: repeat_client, reviewee: strong_profile.user, rating: 5)
    create(:review, contract: second_contract, reviewer: repeat_client, reviewee: strong_profile.user, rating: 5)

    strong_client_job = create(:job, client: strong_profile.user)
    strong_client_contract = create(:contract, :completed, job: strong_client_job, client: strong_profile.user)
    create(:review, contract: strong_client_contract, reviewer: strong_client_contract.freelancer, reviewee: strong_profile.user, rating: 2)

    mixed_client = create(:client_profile).user
    mixed_contract = create(:contract, :completed, job: create(:job, client: mixed_client), client: mixed_client, freelancer: mixed_profile.user)
    create(:review, contract: mixed_contract, reviewer: mixed_client, reviewee: mixed_profile.user, rating: 3)

    create(:shortlist, job: job, client: job.client, freelancer: strong_profile.user)
    create(:shortlist, job: job, client: job.client, freelancer: mixed_profile.user)
    sign_in(job.client)

    get client_job_shortlists_path(job)

    document = Nokogiri::HTML(response.body)
    strong_card = document.css("article").find { |article| article.text.include?(strong_profile.user.name) }.text
    mixed_card = document.css("article").find { |article| article.text.include?(mixed_profile.user.name) }.text

    expect(strong_card).to include("5.0 · 2 reviews", "2 completed contracts", "1 repeat client", "0 low ratings")
    expect(strong_card).not_to include("2.0 · 1 review", "1 low rating")
    expect(mixed_card).to include("3.0 · 1 review", "1 completed contract", "0 repeat clients", "1 low rating")
  end

  it "does not allow another client to view a job's shortlist" do
    job = create(:job)
    sign_in(create(:client_profile).user)

    get client_job_shortlists_path(job)

    expect(response).to have_http_status(:forbidden)
  end

  it "allows the owner to remove a shortlist entry" do
    shortlist = create(:shortlist)
    sign_in(shortlist.client)

    expect do
      delete client_job_shortlist_path(shortlist.job, shortlist)
    end.to change(Shortlist, :count).by(-1)

    expect(response).to redirect_to(client_job_shortlists_path(shortlist.job))
  end

  it "does not allow another client to remove a shortlist entry" do
    shortlist = create(:shortlist)
    sign_in(create(:client_profile).user)

    expect do
      delete client_job_shortlist_path(shortlist.job, shortlist)
    end.not_to change(Shortlist, :count)

    expect(response).to have_http_status(:forbidden)
  end
end
