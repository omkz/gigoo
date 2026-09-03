require "rails_helper"

RSpec.describe "Freelancer proposal drafts", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "lets the owning freelancer review and update a draft without submitting it" do
    proposal = create(:proposal, status: :draft, amount_cents: 125_000, message: "Initial draft")
    sign_in(proposal.freelancer)

    get edit_freelancer_proposal_path(proposal)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Draft · Not submitted", "Initial draft", "Save draft", "Submit proposal")
    expect(response.body).to include(%(href="#{job_path(proposal.job)}">#{proposal.job.title}</a>))

    patch freelancer_proposal_path(proposal), params: {
      proposal: { amount: "1500.75", message: "Updated draft", status: :pending }
    }

    expect(response).to redirect_to(edit_freelancer_proposal_path(proposal))
    expect(proposal.reload).to be_draft
    expect(proposal.amount_cents).to eq(150_075)
    expect(proposal.message).to eq("Updated draft")
  end

  it "forbids another freelancer from reviewing or updating the draft" do
    proposal = create(:proposal, status: :draft)
    sign_in(create(:freelancer_profile).user)

    get edit_freelancer_proposal_path(proposal)
    expect(response).to have_http_status(:forbidden)

    patch freelancer_proposal_path(proposal), params: { proposal: { message: "Stolen edit" } }
    expect(response).to have_http_status(:forbidden)
    expect(proposal.reload.message).not_to eq("Stolen edit")
  end

  describe "submitting a draft" do
    it "lets the owner submit the existing record with an explicit request" do
      proposal = create(:proposal, status: :draft)
      sign_in(proposal.freelancer)

      expect do
        patch submit_freelancer_proposal_path(proposal)
      end.not_to change(Proposal, :count)

      expect(proposal.reload).to be_pending
      expect(response).to redirect_to(job_path(proposal.job))
      follow_redirect!
      expect(response.body).to include("Proposal was submitted to the client.", "Proposal submitted · Pending")
    end

    it "redirects an unauthenticated user to sign in" do
      proposal = create(:proposal, status: :draft)

      patch submit_freelancer_proposal_path(proposal)

      expect(response).to redirect_to(new_session_path)
      expect(proposal.reload).to be_draft
    end

    it "forbids another freelancer and a user without freelancer capability" do
      proposal = create(:proposal, status: :draft)
      sign_in(create(:freelancer_profile).user)

      patch submit_freelancer_proposal_path(proposal)
      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload).to be_draft

      sign_in(create(:user))
      patch submit_freelancer_proposal_path(proposal)
      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload).to be_draft
    end

    it "rejects non-draft proposals and prevents double submission" do
      proposal = create(:proposal, status: :pending)
      sign_in(proposal.freelancer)

      patch submit_freelancer_proposal_path(proposal)

      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload).to be_pending

      draft = create(:proposal, status: :draft)
      sign_in(draft.freelancer)
      patch submit_freelancer_proposal_path(draft)
      expect(draft.reload).to be_pending

      patch submit_freelancer_proposal_path(draft)
      expect(response).to have_http_status(:forbidden)
      expect(draft.reload).to be_pending
    end

    it "rejects a draft when its job is no longer open" do
      proposal = create(:proposal, status: :draft)
      proposal.job.update!(status: :closed)
      sign_in(proposal.freelancer)

      patch submit_freelancer_proposal_path(proposal)

      expect(response).to have_http_status(:forbidden)
      expect(proposal.reload).to be_draft
    end

    it "makes the submitted proposal visible in the client's list and count" do
      proposal = create(:proposal, status: :draft, message: "Reviewed and ready")
      sign_in(proposal.freelancer)
      patch submit_freelancer_proposal_path(proposal)

      sign_in(proposal.job.client)
      get client_job_proposals_path(proposal.job)
      expect(response.body).to include("Reviewed and ready", proposal.freelancer.name)

      get client_jobs_path
      expect(response.body).to include(client_job_proposals_path(proposal.job), "View proposals (1)")
    end
  end
end
