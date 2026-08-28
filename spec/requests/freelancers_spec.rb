require "rails_helper"

RSpec.describe "Freelancers", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "allows a visitor to browse freelancer profiles" do
    user = create(:user, first_name: "Kurnia", last_name: "Muhamad", email_address: "private@example.com")
    profile = create(:freelancer_profile, user: user, title: "Backend Rails Engineer")

    get freelancers_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user.name, profile.title, profile.location, profile.skills.first)
    expect(response.body).not_to include(user.email_address)
  end

  it "allows a visitor to view a freelancer profile" do
    user = create(:user, first_name: "Jane", last_name: "Smith", email_address: "jane.private@example.com")
    profile = create(:freelancer_profile, user: user, title: "Marketplace Specialist", bio: "Deep marketplace experience.")

    get freelancer_path(profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user.name, profile.title, profile.bio, profile.location)
    expect(response.body).to include("$250.00/hr", profile.skills.first)
    expect(response.body).not_to include(user.email_address)
  end

  it "filters q across useful profile text and excludes irrelevant profiles" do
    title_match = create(:freelancer_profile, title: "PostgreSQL Performance Engineer")
    bio_match = create(:freelancer_profile, title: "Database Consultant", bio: "PostgreSQL tuning specialist")
    location_match = create(:freelancer_profile, title: "Platform Engineer", location: "PostgreSQL Bay")
    irrelevant = create(:freelancer_profile, title: "Brand Designer", bio: "Visual identity work", location: "Bali")

    get freelancers_path, params: { q: "PostgreSQL" }

    expect(response.body).to include(title_match.title, bio_match.title, location_match.title)
    expect(response.body).not_to include(irrelevant.title)
  end

  it "filters by the PostgreSQL skills array" do
    matching = create(:freelancer_profile, title: "Ruby Specialist", skills: [ "Ruby", "Rails" ])
    irrelevant = create(:freelancer_profile, title: "Go Specialist", skills: [ "Go" ])

    get freelancers_path, params: { skill: "Ruby" }

    expect(response.body).to include(matching.title)
    expect(response.body).not_to include(irrelevant.title)
  end

  it "offers shortlist actions only for the authenticated client's own eligible jobs" do
    client = create(:client_profile).user
    own_job = create(:job, client: client, status: :draft, title: "My planning job")
    other_job = create(:job, status: :open, title: "Another client's job")
    profile = create(:freelancer_profile)
    sign_in(client)

    get freelancer_path(profile)

    expect(response.body).to include(own_job.title, client_job_shortlists_path(own_job))
    expect(response.body).not_to include(other_job.title)
  end
end
