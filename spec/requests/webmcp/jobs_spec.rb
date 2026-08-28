require "rails_helper"

RSpec.describe "WebMCP jobs", type: :request do
  describe "GET /webmcp/jobs" do
    it "returns only matching open jobs with explicit public client data" do
      client = create(:user, first_name: "Alice", last_name: "Johnson", email_address: "alice.private@example.com")
      profile = create(
        :client_profile,
        user: client,
        company_name: "Northstar Commerce",
        location: "Amsterdam, Netherlands",
        payment_verified: true
      )
      matching = create(
        :job,
        client: client,
        title: "Rails Ecommerce Migration",
        description: "Modernize an ecommerce platform.",
        budget_cents: 300_000,
        skills: [ "Ruby", "Rails", "PostgreSQL" ],
        status: :open
      )
      create(:job, title: "Unrelated open job", skills: [ "Rails" ], status: :open)
      create(:job, title: "Ecommerce design migration", budget_cents: 250_000, skills: [ "Figma" ], status: :open)
      create(:job, title: "Enterprise Rails ecommerce migration", budget_cents: 400_000, skills: [ "Rails" ], status: :open)
      create(:job, title: "Hidden ecommerce draft", skills: [ "Rails" ], status: :draft)
      create(:job, title: "Hidden ecommerce closed", skills: [ "Rails" ], status: :closed)

      get webmcp_jobs_path, params: { query: "ecommerce", skill: "Rails", max_budget_usd: 3_000 }

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload.fetch("count")).to eq(1)
      expect(payload.fetch("jobs")).to contain_exactly(
        include(
          "id" => matching.id,
          "title" => matching.title,
          "description" => matching.description,
          "budget_usd" => 3_000.0,
          "currency" => "USD",
          "skills" => [ "Ruby", "Rails", "PostgreSQL" ],
          "status" => "open",
          "url" => job_path(matching),
          "client" => {
            "profile_id" => profile.id,
            "name" => "Alice Johnson",
            "company_name" => "Northstar Commerce",
            "location" => "Amsterdam, Netherlands",
            "payment_verified" => true
          }
        )
      )
      expect(response.body).not_to include(client.email_address, "email_address", "password_digest", "role")
    end

    it "filters by maximum budget and honors the requested limit" do
      create(:job, title: "Within budget", budget_cents: 100_000, created_at: 1.hour.ago)
      create(:job, title: "Also within budget", budget_cents: 150_000, created_at: 2.hours.ago)
      create(:job, title: "Over budget", budget_cents: 250_000, created_at: 3.hours.ago)

      get webmcp_jobs_path, params: { max_budget_usd: 2_000, limit: 1 }

      payload = response.parsed_body
      expect(payload.fetch("count")).to eq(1)
      expect(payload.dig("jobs", 0, "title")).to eq("Within budget")
    end

    it "returns a useful JSON error for malformed numeric filters" do
      get webmcp_jobs_path, params: { max_budget_usd: "many" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("error")).to include("max_budget_usd")
    end
  end

  describe "GET /webmcp/jobs/:id" do
    it "returns one open job without private account fields" do
      job = create(:job, status: :open)

      get webmcp_job_path(job)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id" => job.id, "title" => job.title, "status" => "open")
      expect(response.body).not_to include(job.client.email_address, "email_address", "password_digest", "role")
    end

    it "treats draft and closed jobs as not found" do
      draft = create(:job, status: :draft)
      closed = create(:job, status: :closed)

      get webmcp_job_path(draft)
      expect(response).to have_http_status(:not_found)

      get webmcp_job_path(closed)
      expect(response).to have_http_status(:not_found)
    end
  end
end
