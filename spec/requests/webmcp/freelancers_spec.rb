require "rails_helper"

RSpec.describe "WebMCP freelancers", type: :request do
  describe "GET /webmcp/freelancers" do
    it "filters profiles and returns batched grounded trust evidence" do
      user = create(:user, first_name: "Kurnia", last_name: "Muhamad", email_address: "kurnia.private@example.com")
      matching = create(
        :freelancer_profile,
        user: user,
        title: "Senior Rails Engineer",
        bio: "Ecommerce migration specialist",
        location: "Yogyakarta, Indonesia",
        hourly_rate_cents: 6_500,
        skills: [ "Ruby", "Rails", "PostgreSQL" ]
      )
      contract = create(:contract, :completed, freelancer: user)
      create(:review, contract: contract, reviewer: contract.client, reviewee: user, rating: 5)
      create(:freelancer_profile, title: "Ecommerce Go Engineer", location: "Yogyakarta, Indonesia", hourly_rate_cents: 4_000, skills: [ "Go" ])
      create(:freelancer_profile, title: "Ecommerce Rails Engineer", location: "Singapore", hourly_rate_cents: 6_000, skills: [ "Rails" ])
      create(:freelancer_profile, title: "Ecommerce Rails Consultant", location: "Yogyakarta, Indonesia", hourly_rate_cents: 7_500, skills: [ "Rails" ])

      get webmcp_freelancers_path, params: {
        query: "ecommerce",
        skill: "Rails",
        location: "Yogyakarta",
        max_hourly_rate_usd: 65,
        limit: 1
      }

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload.fetch("count")).to eq(1)
      expect(payload.fetch("freelancers")).to contain_exactly(
        include(
          "profile_id" => matching.id,
          "name" => "Kurnia Muhamad",
          "title" => "Senior Rails Engineer",
          "hourly_rate_usd" => 65.0,
          "skills" => [ "Ruby", "Rails", "PostgreSQL" ],
          "url" => freelancer_path(matching),
          "trust_evidence" => {
            "average_rating" => 5.0,
            "review_count" => 1,
            "completed_contract_count" => 1,
            "repeat_client_count" => 0,
            "low_rating_count" => 0
          }
        )
      )
      expect(response.body).not_to include(user.email_address, "email_address", "password_digest", "role")
    end

    it "applies limit independently of filtering" do
      create(:freelancer_profile, title: "Newest profile", created_at: 1.hour.ago)
      create(:freelancer_profile, title: "Older profile", created_at: 2.hours.ago)

      get webmcp_freelancers_path, params: { limit: 1 }

      expect(response.parsed_body.fetch("count")).to eq(1)
      expect(response.parsed_body.dig("freelancers", 0, "title")).to eq("Newest profile")
      expect(response.parsed_body.dig("freelancers", 0, "trust_evidence")).to include(
        "average_rating" => nil,
        "review_count" => 0
      )
    end

    it "returns a useful JSON error for an invalid limit" do
      get webmcp_freelancers_path, params: { limit: 21 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("error")).to include("limit")
    end
  end

  describe "GET /webmcp/freelancers/:id" do
    it "returns only freelancer-role reputation for a dual-role user" do
      user = create(:user, first_name: "Dual", last_name: "Professional", email_address: "dual.private@example.com")
      freelancer_profile = create(:freelancer_profile, user: user, title: "Rails Engineer")
      create(:client_profile, user: user)

      freelancer_contract = create(:contract, :completed, freelancer: user)
      freelancer_review = create(
        :review,
        contract: freelancer_contract,
        reviewer: freelancer_contract.client,
        reviewee: user,
        rating: 5,
        body: "Excellent freelancer work."
      )

      client_job = create(:job, client: user)
      client_contract = create(:contract, :completed, job: client_job, client: user)
      client_review = create(
        :review,
        contract: client_contract,
        reviewer: client_contract.freelancer,
        reviewee: user,
        rating: 2,
        body: "This belongs to the client role."
      )

      get webmcp_freelancer_path(freelancer_profile)

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload).to include(
        "profile_id" => freelancer_profile.id,
        "name" => "Dual Professional",
        "title" => freelancer_profile.title,
        "bio" => freelancer_profile.bio,
        "location" => freelancer_profile.location,
        "hourly_rate_usd" => 250.0,
        "skills" => freelancer_profile.skills,
        "url" => freelancer_path(freelancer_profile)
      )
      expect(payload.fetch("trust_evidence")).to include(
        "average_rating" => 5.0,
        "review_count" => 1,
        "completed_contract_count" => 1,
        "low_rating_count" => 0
      )
      expect(payload.fetch("recent_reviews")).to contain_exactly(
        include(
          "rating" => 5,
          "body" => freelancer_review.body,
          "reviewer" => include(
            "name" => freelancer_review.reviewer.name,
            "company_name" => freelancer_review.reviewer.client_profile.company_name
          ),
          "created_at" => freelancer_review.created_at.iso8601
        )
      )
      expect(response.body).not_to include(client_review.body, user.email_address, freelancer_review.reviewer.email_address)
    end
  end
end
