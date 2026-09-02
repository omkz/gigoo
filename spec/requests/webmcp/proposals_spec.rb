require "rails_helper"

RSpec.describe "WebMCP proposal drafts", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  let(:job) { create(:job, status: :open, title: "Build a Rails marketplace") }
  let(:freelancer) { create(:freelancer_profile).user }
  let(:valid_params) do
    {
      job_id: job.id,
      cover_letter: "I can deliver this carefully.",
      proposed_amount_usd: 1_250.75
    }
  end

  describe "POST /webmcp/proposals" do
    it "requires authentication with a JSON error" do
      post webmcp_proposals_path, params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Authentication required")
    end

    it "requires freelancer capability" do
      sign_in(create(:user))

      expect do
        post webmcp_proposals_path, params: valid_params, as: :json
      end.not_to change(Proposal, :count)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq("error" => "You are not authorized to perform this action")
    end

    it "creates an unsent proposal draft with the amount stored in cents" do
      sign_in(freelancer)

      expect do
        post webmcp_proposals_path, params: valid_params, as: :json
      end.to change(Proposal, :count).by(1)

      proposal = Proposal.last
      expect(proposal.freelancer).to eq(freelancer)
      expect(proposal.amount_cents).to eq(125_075)
      expect(proposal.message).to eq("I can deliver this carefully.")
      expect(proposal).to be_draft
      expect(proposal).not_to be_pending

      expect(response).to have_http_status(:created)
      payload = response.parsed_body
      expect(payload).to include(
        "result" => "created",
        "message" => "Proposal draft created. It has not been submitted.",
        "proposal" => { "id" => proposal.id, "status" => "draft" },
        "job" => {
          "id" => job.id,
          "title" => "Build a Rails marketplace",
          "status" => "open",
          "url" => job_path(job)
        },
        "proposed_amount_usd" => 1_250.75,
        "currency" => "USD",
        "review_url" => edit_freelancer_proposal_path(proposal)
      )
      expect(payload.fetch("turbo_stream")).to include(
        %(target="job_#{job.id}_proposal_action"),
        "Proposal draft saved",
        "Not submitted",
        edit_freelancer_proposal_path(proposal)
      )
    end

    it "forbids creating a draft for the freelancer's own job" do
      create(:freelancer_profile, user: job.client)
      sign_in(job.client)

      expect do
        post webmcp_proposals_path, params: valid_params, as: :json
      end.not_to change(Proposal, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects closed jobs as not found" do
      closed_job = create(:job, status: :closed)
      sign_in(freelancer)

      post webmcp_proposals_path, params: valid_params.merge(job_id: closed_job.id), as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Resource not found")
    end

    it "returns validation errors for malformed job and amount input" do
      sign_in(freelancer)

      post webmcp_proposals_path, params: valid_params.merge(job_id: "bad-id"), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "job_id must be a positive integer")

      post webmcp_proposals_path, params: valid_params.merge(proposed_amount_usd: "many"), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "proposed_amount_usd must be a non-negative number")
    end

    it "returns not found for an unknown job" do
      sign_in(freelancer)

      post webmcp_proposals_path, params: valid_params.merge(job_id: 999_999), as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Resource not found")
    end

    it "returns the existing draft without creating or changing a duplicate" do
      draft = create(:proposal, job: job, freelancer: freelancer, status: :draft, amount_cents: 90_000, message: "Keep this draft")
      sign_in(freelancer)

      expect do
        post webmcp_proposals_path, params: valid_params, as: :json
      end.not_to change(Proposal, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "result" => "draft_already_exists",
        "proposal" => { "id" => draft.id, "status" => "draft" },
        "proposed_amount_usd" => 900.0,
        "review_url" => edit_freelancer_proposal_path(draft)
      )
      expect(draft.reload.amount_cents).to eq(90_000)
      expect(draft.message).to eq("Keep this draft")
    end

    it "does not create a draft when a submitted proposal already exists" do
      submitted = create(:proposal, job: job, freelancer: freelancer, status: :pending)
      sign_in(freelancer)

      expect do
        post webmcp_proposals_path, params: valid_params, as: :json
      end.not_to change(Proposal, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "result" => "proposal_already_exists",
        "proposal" => { "id" => submitted.id, "status" => "pending" }
      )
    end

    it "returns domain validation errors without saving or submitting" do
      sign_in(freelancer)

      expect do
        post webmcp_proposals_path,
          params: valid_params.merge(cover_letter: "", proposed_amount_usd: 0),
          as: :json
      end.not_to change(Proposal, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("error")).to include("Amount cents must be greater than 0", "Message can't be blank")
    end
  end

  it "does not expose a WebMCP proposal submission tool" do
    source = Rails.root.join("app/javascript/webmcp.js").read
    registered_tools = source.scan(/name:\s*"([^"]+)"/).flatten

    expect(registered_tools).to contain_exactly(
      "search_jobs",
      "get_job",
      "search_freelancers",
      "get_freelancer",
      "get_client",
      "add_to_shortlist",
      "remove_from_shortlist",
      "create_proposal_draft"
    )
    expect(source).not_to include('name: "submit_proposal"')
  end
end
