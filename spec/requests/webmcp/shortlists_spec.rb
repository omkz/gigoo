require "rails_helper"

RSpec.describe "WebMCP shortlists", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  describe "POST /webmcp/shortlists" do
    it "requires authentication with a JSON error" do
      post webmcp_shortlists_path, params: { job_id: create(:job).id, freelancer_id: create(:freelancer_profile).id }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Authentication required")
    end

    it "adds a freelancer to an owning client's open job shortlist" do
      job = create(:job, title: "Rails marketplace", status: :open)
      profile = create(:freelancer_profile, title: "Senior Rails Developer")
      sign_in(job.client)

      expect do
        post webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: profile.id }, as: :json
      end.to change(job.shortlists, :count).by(1)

      expect(response).to have_http_status(:created)
      payload = response.parsed_body
      shortlist = job.shortlists.last
      expect(payload).to include(
        "result" => "created",
        "message" => "Freelancer added to the shortlist.",
        "shortlist" => include(
          "id" => shortlist.id,
          "created_at" => shortlist.created_at.iso8601,
          "job" => {
            "id" => job.id,
            "title" => "Rails marketplace",
            "status" => "open",
            "shortlist_url" => client_job_shortlists_path(job)
          },
          "freelancer" => {
            "profile_id" => profile.id,
            "name" => profile.user.name,
            "title" => "Senior Rails Developer",
            "url" => freelancer_path(profile)
          }
        )
      )
      expect(shortlist.client).to eq(job.client)
      expect(shortlist.freelancer).to eq(profile.user)
      expect(payload.fetch("turbo_stream")).to include(
        %(target="shortlist_action_job_#{job.id}_freelancer_#{profile.id}"),
        %(target="job_#{job.id}_shortlist_link"),
        %(target="job_#{job.id}_shortlist_contents"),
        "Shortlisted",
        "Shortlist (1)",
        profile.user.name,
        "Senior Rails Developer",
        "No reviews yet"
      )
    end

    it "returns the existing entry when the freelancer is already shortlisted" do
      shortlist = create(:shortlist)
      profile = shortlist.freelancer.freelancer_profile
      sign_in(shortlist.client)

      expect do
        post webmcp_shortlists_path, params: { job_id: shortlist.job_id, freelancer_id: profile.id }, as: :json
      end.not_to change(Shortlist, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "result" => "already_shortlisted",
        "message" => "Freelancer was already on this shortlist.",
        "shortlist" => include("id" => shortlist.id)
      )
    end

    it "forbids a client from mutating another client's shortlist" do
      job = create(:job)
      profile = create(:freelancer_profile)
      sign_in(create(:client_profile).user)

      expect do
        post webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: profile.id }, as: :json
      end.not_to change(Shortlist, :count)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq("error" => "You are not authorized to perform this action")
    end

    it "forbids a user without client capability" do
      job = create(:job)
      profile = create(:freelancer_profile)
      sign_in(create(:user))

      post webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: profile.id }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq("error" => "You are not authorized to perform this action")
    end

    it "treats closed jobs and unknown freelancers as not found" do
      job = create(:job, status: :closed)
      sign_in(job.client)

      post webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: create(:freelancer_profile).id }, as: :json
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Resource not found")

      open_job = create(:job, client: job.client)
      post webmcp_shortlists_path, params: { job_id: open_job.id, freelancer_id: 999_999 }, as: :json
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Resource not found")
    end

    it "returns a validation error for malformed identifiers" do
      job = create(:job)
      sign_in(job.client)

      post webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: "not-an-id" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "freelancer_id must be a positive integer")
    end

    it "forbids self-shortlisting through the domain policy" do
      job = create(:job)
      profile = create(:freelancer_profile, user: job.client)
      sign_in(job.client)

      expect do
        post webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: profile.id }, as: :json
      end.not_to change(Shortlist, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /webmcp/shortlists" do
    it "requires authentication with a JSON error" do
      delete webmcp_shortlists_path, params: { job_id: create(:job).id, freelancer_id: create(:freelancer_profile).id }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Authentication required")
    end

    it "removes a freelancer from an owning client's shortlist" do
      job = create(:job, title: "Rails marketplace")
      profile = create(:freelancer_profile, title: "Senior Rails Developer")
      shortlist = create(:shortlist, job: job, client: job.client, freelancer: profile.user)
      remaining_profile = create(:freelancer_profile, title: "Remaining candidate")
      create(:shortlist, job: job, client: job.client, freelancer: remaining_profile.user)
      sign_in(job.client)

      expect do
        delete webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: profile.id }, as: :json
      end.to change(Shortlist, :count).by(-1)

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload).to include(
        "result" => "removed",
        "message" => "Freelancer removed from the shortlist.",
        "job" => {
          "id" => job.id,
          "title" => "Rails marketplace",
          "status" => "open",
          "shortlist_url" => client_job_shortlists_path(job)
        },
        "freelancer" => {
          "profile_id" => profile.id,
          "name" => profile.user.name,
          "title" => "Senior Rails Developer",
          "url" => freelancer_path(profile)
        },
        "shortlist_count" => 1
      )
      expect(Shortlist.exists?(shortlist.id)).to be(false)
      expect(payload.fetch("turbo_stream")).to include(
        %(target="shortlist_action_job_#{job.id}_freelancer_#{profile.id}"),
        %(target="job_#{job.id}_shortlist_link"),
        %(target="job_#{job.id}_shortlist_contents"),
        client_job_shortlists_path(job),
        "Add",
        "Shortlist (1)",
        remaining_profile.user.name,
        "Remaining candidate"
      )
      expect(payload.fetch("turbo_stream")).not_to include(profile.user.name, "Senior Rails Developer")
    end

    it "replaces the final shortlist entry with the empty state" do
      shortlist = create(:shortlist)
      profile = shortlist.freelancer.freelancer_profile
      sign_in(shortlist.client)

      delete webmcp_shortlists_path,
        params: { job_id: shortlist.job_id, freelancer_id: profile.id },
        as: :json

      expect(response).to have_http_status(:ok)
      turbo_stream = response.parsed_body.fetch("turbo_stream")
      expect(turbo_stream).to include(
        %(target="job_#{shortlist.job_id}_shortlist_contents"),
        %(id="job_#{shortlist.job_id}_shortlist_contents"),
        "No shortlisted freelancers yet.",
        "Shortlist (0)"
      )
      expect(turbo_stream).not_to include(profile.user.name, profile.title)
    end

    it "returns success when the freelancer is already absent" do
      job = create(:job)
      profile = create(:freelancer_profile)
      sign_in(job.client)

      expect do
        delete webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: profile.id }, as: :json
      end.not_to change(Shortlist, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "result" => "already_removed",
        "message" => "Freelancer was already absent from this shortlist.",
        "shortlist_count" => 0
      )
    end

    it "forbids another client from removing an entry" do
      shortlist = create(:shortlist)
      profile = shortlist.freelancer.freelancer_profile
      sign_in(create(:client_profile).user)

      expect do
        delete webmcp_shortlists_path,
          params: { job_id: shortlist.job_id, freelancer_id: profile.id },
          as: :json
      end.not_to change(Shortlist, :count)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq("error" => "You are not authorized to perform this action")
    end

    it "returns a validation error for malformed identifiers" do
      job = create(:job)
      sign_in(job.client)

      delete webmcp_shortlists_path, params: { job_id: 0, freelancer_id: "not-an-id" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "job_id must be a positive integer")
    end

    it "treats unknown jobs and freelancers as not found" do
      job = create(:job)
      sign_in(job.client)

      delete webmcp_shortlists_path, params: { job_id: 999_999, freelancer_id: create(:freelancer_profile).id }, as: :json
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Resource not found")

      delete webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: 999_999 }, as: :json
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Resource not found")
    end

    it "treats an impossible self-shortlist as already removed" do
      job = create(:job)
      profile = create(:freelancer_profile, user: job.client)
      sign_in(job.client)

      expect do
        delete webmcp_shortlists_path, params: { job_id: job.id, freelancer_id: profile.id }, as: :json
      end.not_to change(Shortlist, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("result" => "already_removed", "shortlist_count" => 0)
    end
  end
end
