require "rails_helper"

RSpec.describe "WebMCP clients", type: :request do
  describe "GET /webmcp/clients/:id" do
    it "returns public client data and only client-role reputation for a dual-role user" do
      user = create(:user, first_name: "Alice", last_name: "Johnson", email_address: "alice.private@example.com")
      client_profile = create(
        :client_profile,
        user: user,
        company_name: "Northstar Commerce",
        location: "Amsterdam, Netherlands",
        payment_verified: true
      )
      create(:freelancer_profile, user: user)

      client_job = create(:job, client: user)
      client_contract = create(:contract, :completed, job: client_job, client: user)
      client_review = create(
        :review,
        contract: client_contract,
        reviewer: client_contract.freelancer,
        reviewee: user,
        rating: 2,
        body: "Grounded client feedback."
      )

      freelancer_contract = create(:contract, :completed, freelancer: user)
      freelancer_review = create(
        :review,
        contract: freelancer_contract,
        reviewer: freelancer_contract.client,
        reviewee: user,
        rating: 5,
        body: "This belongs to the freelancer role."
      )

      get webmcp_client_path(client_profile)

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload).to include(
        "profile_id" => client_profile.id,
        "name" => "Alice Johnson",
        "company_name" => "Northstar Commerce",
        "bio" => client_profile.bio,
        "location" => "Amsterdam, Netherlands",
        "payment_verified" => true,
        "url" => client_path(client_profile)
      )
      expect(payload.fetch("trust_evidence")).to eq(
        "average_rating" => 2.0,
        "review_count" => 1,
        "completed_contract_count" => 1,
        "repeat_freelancer_count" => 0,
        "low_rating_count" => 1
      )
      expect(payload.fetch("recent_reviews")).to contain_exactly(
        include(
          "rating" => 2,
          "body" => client_review.body,
          "reviewer" => include(
            "name" => client_review.reviewer.name,
            "title" => client_review.reviewer.freelancer_profile.title
          ),
          "created_at" => client_review.created_at.iso8601
        )
      )
      expect(response.body).not_to include(
        freelancer_review.body,
        user.email_address,
        client_review.reviewer.email_address,
        "email_address",
        "password_digest",
        "role"
      )
    end
  end
end
