require "rails_helper"

RSpec.describe "Freelancer contracts", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "allows the freelancer to view their contract" do
    contract = create(:contract)
    sign_in(contract.freelancer)

    get freelancer_contract_path(contract)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(contract.job.title, contract.client.name)
    expect(response.body).to include(contract.client.client_profile.company_name, "$4,500.00", "Active")
  end

  it "forbids another freelancer from viewing the contract" do
    contract = create(:contract)
    sign_in(create(:freelancer_profile).user)

    get freelancer_contract_path(contract)

    expect(response).to have_http_status(:forbidden)
  end

  it "shows the freelancer review form after completion" do
    contract = create(:contract, :completed)
    sign_in(contract.freelancer)

    get freelancer_contract_path(contract)

    expect(response.body).to include("Completed", "Rate client", "Submit review")
  end

  it "links the freelancer's latest contract from their own profile" do
    contract = create(:contract)
    sign_in(contract.freelancer)

    get freelancer_path(contract.freelancer.freelancer_profile)

    expect(response.body).to include("Your latest contract", contract.job.title)
    expect(response.body).to include(freelancer_contract_path(contract))
  end
end
