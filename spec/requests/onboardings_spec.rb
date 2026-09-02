require "rails_helper"

RSpec.describe "Marketplace capability onboarding", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "requires authentication to view or update onboarding" do
    get onboarding_path
    expect(response).to redirect_to(new_session_path)

    patch onboarding_path, params: { capability: "both" }
    expect(response).to redirect_to(new_session_path)
    expect(ClientProfile.count).to eq(0)
    expect(FreelancerProfile.count).to eq(0)
  end

  it "shows three choices and explains that one account can do both" do
    sign_in(create(:user))

    get onboarding_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "What brings you to Gigoo?",
      "Find work",
      "Create a freelancer presence and find projects.",
      "Hire talent",
      "Post jobs and hire freelancers.",
      "Both",
      "Use the same Gigoo account for freelancing and hiring."
    )
  end

  it "creates only freelancer capability for Find work and redirects to Browse Jobs" do
    user = create(:user)
    sign_in(user)

    expect do
      patch onboarding_path, params: { capability: "find_work" }
    end.to change(FreelancerProfile, :count).by(1).and change(ClientProfile, :count).by(0)

    expect(user.reload.freelancer_profile).to be_present
    expect(user.client_profile).to be_nil
    expect(user).to be_member
    expect(response).to redirect_to(jobs_path)
  end

  it "creates only client capability for Hire talent and redirects to My Jobs" do
    user = create(:user)
    sign_in(user)

    expect do
      patch onboarding_path, params: { capability: "hire_talent" }
    end.to change(ClientProfile, :count).by(1).and change(FreelancerProfile, :count).by(0)

    expect(user.reload.client_profile).to be_present
    expect(user.freelancer_profile).to be_nil
    expect(user).to be_member
    expect(response).to redirect_to(client_jobs_path)
  end

  it "creates both capabilities and redirects to Browse Jobs" do
    user = create(:user)
    sign_in(user)

    expect do
      patch onboarding_path, params: { capability: "both" }
    end.to change(ClientProfile, :count).by(1).and change(FreelancerProfile, :count).by(1)

    expect(user.reload.client_profile).to be_present
    expect(user.freelancer_profile).to be_present
    expect(user).to be_member
    expect(response).to redirect_to(jobs_path)
  end

  it "is idempotent when a capability is selected repeatedly" do
    user = create(:user)
    sign_in(user)
    patch onboarding_path, params: { capability: "both" }

    expect do
      patch onboarding_path, params: { capability: "both" }
    end.to change(ClientProfile, :count).by(0).and change(FreelancerProfile, :count).by(0)

    expect(user.reload.client_profile).to be_present
    expect(user.freelancer_profile).to be_present
  end

  it "adds another capability later without removing the existing one" do
    user = create(:user)
    sign_in(user)
    patch onboarding_path, params: { capability: "find_work" }
    freelancer_profile = user.reload.freelancer_profile

    expect do
      patch onboarding_path, params: { capability: "hire_talent" }
    end.to change(ClientProfile, :count).by(1).and change(FreelancerProfile, :count).by(0)

    expect(user.reload.freelancer_profile).to eq(freelancer_profile)
    expect(user.client_profile).to be_present
    expect(response).to redirect_to(client_jobs_path)
  end
end
