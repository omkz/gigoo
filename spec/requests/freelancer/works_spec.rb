require "rails_helper"

RSpec.describe "Freelancer My Work", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "redirects an unauthenticated user to sign in" do
    get freelancer_work_path

    expect(response).to redirect_to(new_session_path)
  end

  it "forbids an authenticated user without freelancer capability" do
    sign_in(create(:user))

    get freelancer_work_path

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to be_blank
  end

  it "shows only the current freelancer's proposals" do
    freelancer = create(:freelancer_profile).user
    own = create(:proposal, freelancer: freelancer, job: create(:job, title: "My proposal job"))
    other = create(:proposal, job: create(:job, title: "Another freelancer's job"))
    sign_in(freelancer)

    get freelancer_work_path

    expect(response.body).to include("My Work", own.job.title)
    expect(response.body).not_to include(other.job.title)
  end

  it "shows only the current freelancer's contracts" do
    freelancer = create(:freelancer_profile).user
    own = create(:contract, freelancer: freelancer, job: create(:job, title: "My contract job"))
    other = create(:contract, job: create(:job, title: "Another freelancer's contract job"))
    sign_in(freelancer)

    get freelancer_work_path

    expect(response.body).to include(own.job.title, freelancer_contract_path(own))
    expect(response.body).not_to include(other.job.title, freelancer_contract_path(other))
  end

  it "orders proposals newest first" do
    freelancer = create(:freelancer_profile).user
    older = create(:proposal, freelancer: freelancer, job: create(:job, title: "Older proposal job"), created_at: 2.days.ago)
    newer = create(:proposal, freelancer: freelancer, job: create(:job, title: "Newer proposal job"), created_at: 1.hour.ago)
    sign_in(freelancer)

    get freelancer_work_path

    expect(response.body.index(newer.job.title)).to be < response.body.index(older.job.title)
  end

  it "shows draft, pending, rejected, and withdrawn proposal states" do
    freelancer = create(:freelancer_profile).user
    draft = create(:proposal, freelancer: freelancer, status: :draft)
    pending = create(:proposal, freelancer: freelancer, status: :pending)
    rejected = create(:proposal, freelancer: freelancer, status: :rejected)
    withdrawn = create(:proposal, freelancer: freelancer, status: :withdrawn)
    sign_in(freelancer)

    get freelancer_work_path

    expect(response.body).to include(
      draft.job.title,
      "Draft · Not submitted",
      "Review and edit",
      edit_freelancer_proposal_path(draft),
      pending.job.title,
      "Pending",
      rejected.job.title,
      "Rejected",
      withdrawn.job.title,
      "Withdrawn"
    )
  end

  it "links an accepted proposal to its freelancer contract" do
    freelancer = create(:freelancer_profile).user
    proposal = create(:proposal, freelancer: freelancer, status: :accepted)
    contract = create(
      :contract,
      job: proposal.job,
      client: proposal.job.client,
      freelancer: freelancer,
      amount_cents: proposal.amount_cents
    )
    proposal.job.update!(status: :closed)
    sign_in(freelancer)

    get freelancer_work_path

    expect(response.body).to include(proposal.job.title, "Accepted", freelancer_contract_path(contract))
  end

  it "shows active and completed contracts in their respective sections" do
    freelancer = create(:freelancer_profile).user
    active = create(:contract, freelancer: freelancer, started_at: 3.days.ago)
    completed = create(:contract, :completed, freelancer: freelancer, completed_at: 1.day.ago)
    sign_in(freelancer)

    get freelancer_work_path

    active_heading = response.body.index("Active contracts")
    proposals_heading = response.body.index("Proposals")
    completed_heading = response.body.index("Completed contracts")
    expect(active_heading).to be < proposals_heading
    expect(proposals_heading).to be < completed_heading
    expect(response.body).to include(
      active.job.title,
      "Active",
      freelancer_contract_path(active),
      completed.job.title,
      "Completed",
      freelancer_contract_path(completed)
    )
  end

  it "does not link a closed job to the unavailable public job page" do
    freelancer = create(:freelancer_profile).user
    proposal = create(:proposal, freelancer: freelancer, status: :rejected)
    proposal.job.update!(status: :closed)
    sign_in(freelancer)

    get freelancer_work_path

    expect(response.body).to include(proposal.job.title, "Rejected")
    expect(response.body).not_to include(%(href="#{job_path(proposal.job)}"))
  end

  it "shows the empty workspace Browse jobs call to action" do
    freelancer = create(:freelancer_profile).user
    sign_in(freelancer)

    get freelancer_work_path

    expect(response.body).to include(
      "Your freelance work will appear here.",
      "Browse jobs",
      jobs_path
    )
  end

  it "shows capability-aware workspace navigation" do
    freelancer = create(:freelancer_profile).user
    sign_in(freelancer)
    get jobs_path
    expect(response.body).to include(%(href="#{freelancer_work_path}"), ">My work</a>")
    expect(response.body).not_to include(">My jobs</a>")

    client = create(:client_profile).user
    reset!
    sign_in(client)
    get jobs_path
    expect(response.body).to include(">My jobs</a>")
    expect(response.body).not_to include(">My work</a>")

    dual_user = create(:user)
    create(:freelancer_profile, user: dual_user)
    create(:client_profile, user: dual_user)
    reset!
    sign_in(dual_user)
    get jobs_path
    expect(response.body).to include(">My work</a>")
    expect(response.body).not_to include(">My jobs</a>")

    patch workspace_path, params: { workspace: "client" }
    get jobs_path
    expect(response.body).to include(">My jobs</a>")
    expect(response.body).not_to include(">My work</a>")
  end

  it "shows a WebMCP-created proposal draft" do
    freelancer = create(:freelancer_profile).user
    job = create(:job, title: "WebMCP draft job")
    sign_in(freelancer)

    post webmcp_proposals_path, params: {
      job_id: job.id,
      cover_letter: "Drafted with the agent",
      proposed_amount_usd: 1_200
    }, as: :json
    expect(response).to have_http_status(:created)
    proposal = Proposal.last

    get freelancer_work_path

    expect(response.body).to include(
      "WebMCP draft job",
      "Draft · Not submitted",
      edit_freelancer_proposal_path(proposal)
    )
  end
end
