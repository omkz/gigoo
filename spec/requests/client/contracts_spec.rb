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
    expect(response.body).to include("$4,500.00", "Active")
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
end
