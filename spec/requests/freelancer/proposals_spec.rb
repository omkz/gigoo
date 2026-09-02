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
    expect(response.body).to include("Draft · Not submitted", "Initial draft", "Save draft")

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
end
