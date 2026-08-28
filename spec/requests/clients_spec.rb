require "rails_helper"

RSpec.describe "Clients", type: :request do
  it "publicly shows client details and grounded received reputation" do
    user = create(:user, first_name: "Jane", last_name: "Smith", email_address: "jane.private@example.com")
    profile = create(:client_profile, user: user, company_name: "Acme Labs", payment_verified: true)
    first_job = create(:job, client: user)
    second_job = create(:job, client: user)
    first_contract = create(:contract, :completed, job: first_job, client: user)
    second_contract = create(:contract, :completed, job: second_job, client: user)
    first_review = create(:review, contract: first_contract, reviewer: first_contract.freelancer, reviewee: user, rating: 5, body: "Clear scope and fast payment.")
    second_review = create(:review, contract: second_contract, reviewer: second_contract.freelancer, reviewee: user, rating: 4, body: "A reliable client.")
    unrelated = create(:review, body: "Another client's review.")

    get client_path(profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Acme Labs", "Jane Smith", profile.location, "Payment verified")
    expect(response.body).to include("4.5 · 2 reviews", first_review.body, second_review.body)
    expect(response.body).to include("Trust evidence", "2 completed contracts", "0 repeat freelancers", "0 low ratings")
    expect(response.body).to include(first_review.reviewer.name)
    expect(response.body).not_to include(unrelated.body, user.email_address, first_review.reviewer.email_address)
  end

  it "shows factual no-history states" do
    profile = create(:client_profile, payment_verified: false)

    get client_path(profile)

    expect(response.body).to include("Trust evidence", "Payment not yet verified", "No reviews yet", "No completed contracts yet")
    expect(response.body).not_to include("0.0 ·", "Untrusted", "Low trust")
  end
end
