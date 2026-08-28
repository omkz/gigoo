require "rails_helper"

RSpec.describe "Role-scoped reputation", type: :request do
  it "keeps a dual-role user's freelancer and client reputation separate" do
    user = create(:user)
    client_profile = create(:client_profile, user: user)
    freelancer_profile = create(:freelancer_profile, user: user)

    freelancer_contract = create(:contract, :completed, freelancer: user)
    freelancer_review = create(
      :review,
      contract: freelancer_contract,
      reviewer: freelancer_contract.client,
      reviewee: user,
      rating: 5,
      body: "Excellent freelancer."
    )

    client_job = create(:job, client: user)
    client_contract = create(:contract, :completed, job: client_job, client: user)
    client_review = create(
      :review,
      contract: client_contract,
      reviewer: client_contract.freelancer,
      reviewee: user,
      rating: 2,
      body: "Difficult client."
    )

    get freelancer_path(freelancer_profile)

    expect(response.body).to include("5.0 · 1 review", freelancer_review.body)
    expect(response.body).to include("1 completed contract", "0 repeat clients", "0 low ratings")
    expect(response.body).not_to include(client_review.body, "3.5 · 2 reviews")

    get client_path(client_profile)

    expect(response.body).to include("2.0 · 1 review", client_review.body)
    expect(response.body).to include("1 completed contract", "0 repeat freelancers", "1 low rating")
    expect(response.body).not_to include(freelancer_review.body, "3.5 · 2 reviews")
  end
end
