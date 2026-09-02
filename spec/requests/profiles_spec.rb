require "rails_helper"

RSpec.describe "Self-service profiles", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "requires authentication for the Profile area" do
    get profile_path
    expect(response).to redirect_to(new_session_path)

    get edit_profile_freelancer_path
    expect(response).to redirect_to(new_session_path)

    patch profile_client_path, params: { client_profile: { company_name: "No access" } }
    expect(response).to redirect_to(new_session_path)
  end

  it "shows freelancer data and a link to add client capability" do
    profile = create(
      :freelancer_profile,
      title: "Rails Consultant",
      location: "Bandung",
      hourly_rate_cents: 12_550,
      skills: [ "Ruby", "Hotwire" ],
      bio: "Reliable marketplace builder."
    )
    sign_in(profile.user)

    get profile_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "Profile",
      "Freelancer",
      "Rails Consultant",
      "Bandung",
      "$125.50 USD/hour",
      "Ruby, Hotwire",
      "Reliable marketplace builder.",
      "Edit freelancer profile",
      freelancer_path(profile),
      "Start hiring",
      onboarding_path
    )
    expect(response.body).not_to include("Edit client profile")
  end

  it "shows client data, read-only verification, and a link to add freelancer capability" do
    profile = create(
      :client_profile,
      company_name: "Northstar Labs",
      location: "Jakarta",
      bio: "We build trusted products.",
      payment_verified: true
    )
    sign_in(profile.user)

    get profile_path

    expect(response.body).to include(
      "Client",
      "Northstar Labs",
      "Jakarta",
      "We build trusted products.",
      "Payment verified",
      "Edit client profile",
      client_path(profile),
      "Start freelancing",
      onboarding_path
    )
    expect(response.body).not_to include("Edit freelancer profile")
  end

  it "shows both marketplace profiles for one account" do
    user = create(:user)
    freelancer = create(:freelancer_profile, user: user, title: "Product Engineer")
    client = create(:client_profile, user: user, company_name: "Dual Studio")
    sign_in(user)

    get profile_path

    expect(response.body).to include(
      "Freelancer",
      freelancer.title,
      "Edit freelancer profile",
      "Client",
      client.company_name,
      "Edit client profile"
    )
    expect(response.body).not_to include("Start hiring", "Start freelancing")
  end

  it "updates freelancer fields, converts hourly rate, and normalizes skills" do
    profile = create(:freelancer_profile, hourly_rate_cents: 5_000)
    original_user = profile.user
    other_user = create(:user)
    sign_in(original_user)

    patch profile_freelancer_path, params: {
      freelancer_profile: {
        title: "Senior Rails Engineer",
        location: "Yogyakarta",
        hourly_rate: "87.65",
        skills: " Ruby, Rails, , PostgreSQL, Rails ",
        bio: "I ship dependable systems.",
        user_id: other_user.id
      }
    }

    expect(response).to redirect_to(profile_path)
    expect(profile.reload).to have_attributes(
      title: "Senior Rails Engineer",
      location: "Yogyakarta",
      hourly_rate_cents: 8_765,
      skills: [ "Ruby", "Rails", "PostgreSQL" ],
      bio: "I ship dependable systems.",
      user_id: original_user.id
    )
    expect(original_user.reload).to be_member
  end

  it "renders useful validation errors for an invalid hourly rate" do
    profile = create(:freelancer_profile, hourly_rate_cents: 5_000)
    sign_in(profile.user)

    patch profile_freelancer_path, params: {
      freelancer_profile: { hourly_rate: "not-a-rate", skills: profile.skills.join(", ") }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Hourly rate must be a non-negative number", "not-a-rate")
    expect(profile.reload.hourly_rate_cents).to eq(5_000)
  end

  it "updates client fields without allowing payment verification or ownership changes" do
    profile = create(:client_profile, payment_verified: false)
    original_user = profile.user
    other_user = create(:user)
    sign_in(original_user)

    patch profile_client_path, params: {
      client_profile: {
        company_name: "Updated Company",
        location: "Surabaya",
        bio: "Updated client biography.",
        payment_verified: true,
        user_id: other_user.id
      }
    }

    expect(response).to redirect_to(profile_path)
    expect(profile.reload).to have_attributes(
      company_name: "Updated Company",
      location: "Surabaya",
      bio: "Updated client biography.",
      payment_verified: false,
      user_id: original_user.id
    )
    expect(original_user.reload).to be_member
  end

  it "cannot edit another user's profile or create one through the singular routes" do
    user = create(:user)
    other_freelancer = create(:freelancer_profile)
    other_client = create(:client_profile)
    sign_in(user)

    expect do
      get edit_profile_freelancer_path, params: { id: other_freelancer.id }
    end.not_to change(FreelancerProfile, :count)
    expect(response).to have_http_status(:not_found)

    expect do
      patch profile_client_path, params: {
        id: other_client.id,
        client_profile: { company_name: "Hijacked", user_id: user.id }
      }
    end.not_to change(ClientProfile, :count)
    expect(response).to have_http_status(:not_found)
    expect(other_client.reload.company_name).not_to eq("Hijacked")
  end

  it "keeps public profile pages working after self-service updates" do
    user = create(:user)
    freelancer = create(:freelancer_profile, user: user, title: "Public Freelancer")
    client = create(:client_profile, user: user, company_name: "Public Client")
    sign_in(user)

    get freelancer_path(freelancer)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Public Freelancer")

    get client_path(client)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Public Client")
  end

  it "shows Profile in the authenticated navigation" do
    sign_in(create(:user))

    get jobs_path

    expect(response.body).to include(%(href="#{profile_path}"), ">Profile</a>")
  end

  it "shows the account section with name, email, and an edit link" do
    user = create(:user, first_name: "Kurnia", last_name: "Muhamad", email_address: "kurnia@example.com")
    sign_in(user)

    get profile_path

    expect(response.body).to include("Account", "Kurnia Muhamad", "kurnia@example.com", "Edit account", edit_profile_account_path)
  end

  it "renders the account section for a user with no marketplace capability yet" do
    user = create(:user, first_name: "Nia", last_name: "Solo")
    sign_in(user)

    get profile_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Account", "Nia Solo", user.email_address, "Choose a capability", onboarding_path)
  end

  it "requires authentication to edit the account" do
    get edit_profile_account_path
    expect(response).to redirect_to(new_session_path)

    patch profile_account_path, params: { user: { first_name: "Nope" } }
    expect(response).to redirect_to(new_session_path)
  end

  it "updates the authenticated user's first and last name" do
    user = create(:user, first_name: "Old", last_name: "Name")
    sign_in(user)

    patch profile_account_path, params: { user: { first_name: "New", last_name: "Person" } }

    expect(response).to redirect_to(profile_path)
    follow_redirect!
    expect(response.body).to include("Account was updated.")
    expect(user.reload).to have_attributes(first_name: "New", last_name: "Person")
  end

  it "does not allow email_address or role to be changed through the account form" do
    user = create(:user, email_address: "original@example.com", role: :member)
    sign_in(user)

    patch profile_account_path, params: {
      user: { first_name: "New", email_address: "hijacked@example.com", role: "admin" }
    }

    expect(response).to redirect_to(profile_path)
    user.reload
    expect(user.email_address).to eq("original@example.com")
    expect(user).to be_member
    expect(user.first_name).to eq("New")
  end

  it "ignores a spoofed user_id and only ever updates the authenticated user" do
    user = create(:user, first_name: "Mine")
    other_user = create(:user, first_name: "Theirs")
    sign_in(user)

    patch profile_account_path, params: { user: { first_name: "Changed", user_id: other_user.id } }

    expect(response).to redirect_to(profile_path)
    expect(user.reload.first_name).to eq("Changed")
    expect(other_user.reload.first_name).to eq("Theirs")
  end

  it "renders validation errors for the account form with a 422 status" do
    user = create(:user, first_name: "Keep")
    sign_in(user)

    patch profile_account_path, params: { user: { first_name: "", last_name: "" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("First name can&#39;t be blank", "Last name can&#39;t be blank")
    expect(user.reload.first_name).to eq("Keep")
  end
end
