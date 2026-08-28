require "rails_helper"

RSpec.describe "Client contracts", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "allows the client to view contract details" do
    freelancer = create(:user, first_name: "Kurnia", last_name: "Muhamad")
    create(:freelancer_profile, user: freelancer)
    contract = create(:contract, freelancer: freelancer, amount_cents: 450_000, status: :active)
    profile = contract.freelancer.freelancer_profile
    sign_in(contract.client)

    get client_contract_path(contract)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(contract.job.title, contract.freelancer.name, profile.title)
    expect(response.body).to include("$4,500.00", "Active", "Mark contract complete")
  end

  it "redirects an unauthenticated visitor to sign in" do
    get client_contract_path(create(:contract))

    expect(response).to redirect_to(new_session_path)
  end

  it "forbids another client from viewing the contract" do
    contract = create(:contract)
    sign_in(create(:client_profile).user)

    get client_contract_path(contract)

    expect(response).to have_http_status(:forbidden)
  end

  it "allows the owning client to complete an active contract" do
    contract = create(:contract, status: :active, completed_at: nil)
    sign_in(contract.client)

    patch complete_client_contract_path(contract)

    expect(response).to redirect_to(client_contract_path(contract))
    expect(contract.reload).to be_completed
    expect(contract.completed_at).to be_present
  end

  it "shows the client review form after completion" do
    contract = create(:contract, :completed)
    sign_in(contract.client)

    get client_contract_path(contract)

    expect(response.body).to include("Completed", "Rate freelancer", "Submit review")
    expect(response.body).not_to include("Mark contract complete")
  end

  it "shows an existing client review instead of another form" do
    review = create(:review, rating: 4, body: "Strong delivery throughout.")
    sign_in(review.contract.client)

    get client_contract_path(review.contract)

    expect(response.body).to include("Strong delivery throughout.", "★★★★")
    expect(response.body).not_to include("Submit review")
  end

  it "does not allow the freelancer or another client to complete the contract" do
    contract = create(:contract)

    [ contract.freelancer, create(:client_profile).user ].each do |user|
      sign_in(user)
      patch complete_client_contract_path(contract)

      expect(response).to have_http_status(:forbidden)
      expect(contract.reload).to be_active
    end
  end

  it "does not allow an owner without a client profile to complete the contract" do
    contract = create(:contract)
    contract.client.client_profile.destroy!
    sign_in(contract.client)

    patch complete_client_contract_path(contract)

    expect(response).to have_http_status(:forbidden)
    expect(contract.reload).to be_active
  end

  %i[ support admin ].each do |role|
    it "does not give #{role} an ownership bypass for completion" do
      contract = create(:contract)
      privileged_user = create(:user, role: role)
      create(:client_profile, user: privileged_user)
      sign_in(privileged_user)

      patch complete_client_contract_path(contract)

      expect(response).to have_http_status(:forbidden)
      expect(contract.reload).to be_active
    end
  end

  %i[ completed cancelled ].each do |status|
    it "does not complete a #{status} contract" do
      contract = create(:contract, status: status)
      sign_in(contract.client)

      patch complete_client_contract_path(contract)

      expect(response).to have_http_status(:forbidden)
      expect(contract.reload.status).to eq(status.to_s)
    end
  end
end
