require "rails_helper"

RSpec.describe "Marketplace workspace switching", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  def dual_capability_user
    user = create(:user)
    create(:freelancer_profile, user: user)
    create(:client_profile, user: user)
    user
  end

  it "shows freelancer navigation and hides client navigation for a freelancer-only user" do
    user = create(:freelancer_profile).user
    sign_in(user)

    get jobs_path

    expect(response.body).to include(">Browse jobs</a>", ">My work</a>")
    expect(response.body).not_to include(">Find freelancers</a>", ">My jobs</a>", ">Post a job</a>")
  end

  it "shows client navigation and hides freelancer navigation for a client-only user" do
    user = create(:client_profile).user
    sign_in(user)

    get jobs_path

    expect(response.body).to include(">Find freelancers</a>", ">My jobs</a>", ">Post a job</a>")
    expect(response.body).not_to include(">Browse jobs</a>", ">My work</a>")
  end

  it "defaults a dual-capability user with no stored preference to the freelancer workspace" do
    user = dual_capability_user
    sign_in(user)

    get jobs_path

    expect(response.body).to include(">Browse jobs</a>", ">My work</a>")
    expect(response.body).not_to include(">My jobs</a>", ">Post a job</a>")
    expect(session[:workspace]).to eq("freelancer")
  end

  it "shows client links and hides freelancer links once a dual-capability user switches to client" do
    user = dual_capability_user
    sign_in(user)

    patch workspace_path, params: { workspace: "client" }
    get jobs_path

    expect(response.body).to include(">Find freelancers</a>", ">My jobs</a>", ">Post a job</a>")
    expect(response.body).not_to include(">Browse jobs</a>", ">My work</a>")
  end

  it "shows a workspace switcher only for dual-capability users" do
    dual_user = dual_capability_user
    sign_in(dual_user)
    get jobs_path
    expect(response.body).to include("Freelancer &#9662;")

    freelancer_only = create(:freelancer_profile).user
    reset!
    sign_in(freelancer_only)
    get jobs_path
    expect(response.body).not_to include("&#9662;")

    client_only = create(:client_profile).user
    reset!
    sign_in(client_only)
    get jobs_path
    expect(response.body).not_to include("&#9662;")
  end

  it "places the workspace switcher before workspace-specific links for a dual-capability user" do
    user = dual_capability_user
    sign_in(user)

    get jobs_path
    switcher_index = response.body.index("Freelancer &#9662;")
    browse_jobs_index = response.body.index(">Browse jobs</a>")
    my_work_index = response.body.index(">My work</a>")
    expect(switcher_index).to be < browse_jobs_index
    expect(switcher_index).to be < my_work_index

    patch workspace_path, params: { workspace: "client" }
    get jobs_path
    switcher_index = response.body.index("Client &#9662;")
    find_freelancers_index = response.body.index(">Find freelancers</a>")
    my_jobs_index = response.body.index(">My jobs</a>")
    post_a_job_index = response.body.index(">Post a job</a>")
    expect(switcher_index).to be < find_freelancers_index
    expect(switcher_index).to be < my_jobs_index
    expect(switcher_index).to be < post_a_job_index
  end

  it "updates the session when switching from freelancer to client" do
    user = dual_capability_user
    sign_in(user)

    patch workspace_path, params: { workspace: "client" }

    expect(session[:workspace]).to eq("client")
  end

  it "updates the session when switching from client to freelancer" do
    user = dual_capability_user
    sign_in(user)
    patch workspace_path, params: { workspace: "client" }

    patch workspace_path, params: { workspace: "freelancer" }

    expect(session[:workspace]).to eq("freelancer")
  end

  it "redirects to the appropriate workspace home after switching" do
    user = dual_capability_user
    sign_in(user)

    patch workspace_path, params: { workspace: "client" }
    expect(response).to redirect_to(client_jobs_path)

    patch workspace_path, params: { workspace: "freelancer" }
    expect(response).to redirect_to(jobs_path)
  end

  it "does not allow switching to a capability the user does not have" do
    freelancer_only = create(:freelancer_profile).user
    sign_in(freelancer_only)

    patch workspace_path, params: { workspace: "client" }

    expect(session[:workspace]).to eq("freelancer")
    expect(response).to redirect_to(jobs_path)
  end

  it "safely ignores an invalid workspace value instead of storing it" do
    user = dual_capability_user
    sign_in(user)

    patch workspace_path, params: { workspace: "admin" }

    expect(session[:workspace]).to eq("freelancer")
    expect(response).to redirect_to(jobs_path)
  end

  it "falls back to a remaining valid workspace when the stored one becomes unavailable" do
    user = dual_capability_user
    sign_in(user)
    patch workspace_path, params: { workspace: "client" }
    expect(session[:workspace]).to eq("client")

    user.client_profile.destroy!
    get jobs_path

    expect(response.body).to include(">Browse jobs</a>", ">My work</a>")
    expect(session[:workspace]).to eq("freelancer")
  end

  it "keeps Profile and Sign out visible in both workspaces" do
    user = dual_capability_user
    sign_in(user)

    get jobs_path
    expect(response.body).to include(">Profile</a>", ">Sign out<")

    patch workspace_path, params: { workspace: "client" }
    get jobs_path
    expect(response.body).to include(">Profile</a>", ">Sign out<")
  end

  it "does not change User.role when switching workspaces" do
    user = dual_capability_user
    sign_in(user)

    expect do
      patch workspace_path, params: { workspace: "client" }
    end.not_to change { user.reload.role }

    expect(user.reload).to be_member
  end

  it "does not create or delete marketplace profiles when switching workspaces" do
    user = dual_capability_user
    sign_in(user)

    expect do
      patch workspace_path, params: { workspace: "client" }
      patch workspace_path, params: { workspace: "freelancer" }
    end.not_to change(FreelancerProfile, :count)

    expect do
      patch workspace_path, params: { workspace: "client" }
      patch workspace_path, params: { workspace: "freelancer" }
    end.not_to change(ClientProfile, :count)

    expect(user.reload.freelancer_profile).to be_present
    expect(user.client_profile).to be_present
  end

  it "keeps direct-route authorization based on policies, not the active workspace" do
    user = dual_capability_user
    sign_in(user)
    job = create(:job, client: user, status: :open)

    # Freelancer workspace is active, but the user is still authorized for client-owned routes.
    get client_jobs_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(job.title)

    get freelancer_work_path
    expect(response).to have_http_status(:ok)
  end

  it "lets a dual-capability user access both sets of authorized routes directly regardless of active workspace" do
    user = dual_capability_user
    sign_in(user)

    patch workspace_path, params: { workspace: "client" }

    get freelancer_work_path
    expect(response).to have_http_status(:ok)

    get client_jobs_path
    expect(response).to have_http_status(:ok)
  end

  it "sets the client workspace automatically when visiting a client-owned area" do
    user = dual_capability_user
    sign_in(user)
    expect(session[:workspace]).to be_nil

    get client_jobs_path

    expect(session[:workspace]).to eq("client")
  end

  it "sets the freelancer workspace automatically when visiting a freelancer-owned area" do
    user = dual_capability_user
    sign_in(user)
    patch workspace_path, params: { workspace: "client" }

    get freelancer_work_path

    expect(session[:workspace]).to eq("freelancer")
  end
end
