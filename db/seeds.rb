# Deterministic demo dataset for the Gigoo WebMCP hackathon video.
#
# Two primary actors carry the demo:
#   - Emily Carter (emily@gigoo.test)  -- client, owns the reserved live-demo job
#   - Kurnia Muhamad (kurnia@gigoo.test) -- freelancer, the strongest under-$60/hr candidate
#
# "Build Rails Marketplace Features" (Emily's job) is sacred demo state: it must
# stay open, contract-free, proposal-free, and shortlist-free after every run of
# `bin/rails db:reset`, so the video can add a proposal draft and a shortlist
# entry live. Everything else in this file exists to make the surrounding
# marketplace look real (open jobs, historical contracts, varied reviews).
DEMO_PASSWORD = "password"

def usd_cents(amount)
  (BigDecimal(amount.to_s) * 100).round.to_i
end

def find_or_create_user(email:, first_name:, last_name:)
  user = User.find_or_initialize_by(email_address: email)
  user.assign_attributes(
    first_name: first_name,
    last_name: last_name,
    role: :member,
    password: DEMO_PASSWORD,
    password_confirmation: DEMO_PASSWORD
  )
  user.save!
  user
end

def find_or_create_client_profile(user:, company_name:, location:, payment_verified:, bio:)
  profile = ClientProfile.find_or_initialize_by(user: user)
  profile.update!(company_name: company_name, location: location, payment_verified: payment_verified, bio: bio)
  profile
end

def find_or_create_freelancer_profile(user:, title:, location:, hourly_rate_usd:, skills:, bio:)
  profile = FreelancerProfile.find_or_initialize_by(user: user)
  profile.update!(title: title, location: location, hourly_rate_cents: usd_cents(hourly_rate_usd), skills: skills, bio: bio)
  profile
end

def find_or_create_job(client:, title:, description:, budget_usd:, skills:, status:)
  job = Job.find_or_initialize_by(client: client, title: title)
  job.update!(description: description, budget_cents: usd_cents(budget_usd), skills: skills, status: status)
  job
end

def find_or_create_proposal(job:, freelancer:, amount_usd:, status:, message:)
  proposal = Proposal.find_or_initialize_by(job: job, freelancer: freelancer)
  # Every proposal must pass through :pending first -- Job#open? is required by
  # the model validation, and the job is still open at this point in the seed.
  proposal.assign_attributes(amount_cents: usd_cents(amount_usd), message: message, status: :pending)
  proposal.save!
  proposal.update!(status: status) unless proposal.status == status.to_s
  proposal
end

def find_or_create_contract(job:, freelancer:, status:, started_at:, completed_at:)
  proposal = Proposal.find_by!(job: job, freelancer: freelancer)
  contract = Contract.find_or_initialize_by(job: job)
  contract.update!(
    client: job.client,
    freelancer: proposal.freelancer,
    amount_cents: proposal.amount_cents,
    status: status,
    started_at: Time.zone.parse(started_at),
    completed_at: completed_at && Time.zone.parse(completed_at)
  )
  # Accepting a proposal always closes its job -- keep the seed state consistent
  # with what the application itself would do.
  job.update!(status: :closed)
  contract
end

def find_or_create_review(contract:, reviewer:, reviewee:, rating:, body:)
  review = Review.find_or_initialize_by(contract: contract, reviewer: reviewer)
  review.update!(reviewee: reviewee, rating: rating, body: body)
  review
end

def find_or_create_shortlist(job:, freelancer:)
  shortlist = Shortlist.find_or_initialize_by(job: job, client: job.client, freelancer: freelancer)
  shortlist.save!
  shortlist
end

users = {}
jobs = {}

ApplicationRecord.transaction do
  # -- Users -----------------------------------------------------------------
  {
    emily: [ "Emily", "Carter" ],
    kurnia: [ "Kurnia", "Muhamad" ],
    michael: [ "Michael", "Davis" ],
    sarah: [ "Sarah", "Miller" ],
    james: [ "James", "Wilson" ],
    grace: [ "Grace", "Taylor" ],
    olivia: [ "Olivia", "Brown" ],
    daniel: [ "Daniel", "Moore" ],
    sophia: [ "Sophia", "Anderson" ],
    ethan: [ "Ethan", "Thomas" ],
    noah: [ "Noah", "Martin" ],
    ava: [ "Ava", "Thompson" ]
  }.each do |key, (first_name, last_name)|
    users[key] = find_or_create_user(email: "#{key}@gigoo.test", first_name: first_name, last_name: last_name)
  end

  # -- Client profiles (5): Emily is the primary demo client -----------------
  find_or_create_client_profile(
    user: users[:emily], company_name: "Northstar Labs", location: "San Francisco, USA", payment_verified: true,
    bio: "Building Northstar Labs' marketplace platform with an emphasis on reliable delivery, clear scope, and long-term technical partnerships."
  )
  find_or_create_client_profile(
    user: users[:michael], company_name: "GrowthForge", location: "Austin, USA", payment_verified: true,
    bio: "Analytics and acquisition tools for growing online businesses."
  )
  find_or_create_client_profile(
    user: users[:sarah], company_name: "Meridian Health", location: "Denver, USA", payment_verified: true,
    bio: "Healthcare operations software with an emphasis on dependable delivery."
  )
  find_or_create_client_profile(
    user: users[:james], company_name: "Atlas Commerce", location: "Chicago, USA", payment_verified: false,
    bio: "Ecommerce operations tooling for mid-market retailers."
  )
  find_or_create_client_profile(
    user: users[:grace], company_name: "BrightPath Studio", location: "Portland, USA", payment_verified: true,
    bio: "Subscription products for independent education businesses."
  )

  # -- Freelancer profiles (8): Kurnia is the primary demo freelancer --------
  find_or_create_freelancer_profile(
    user: users[:kurnia], title: "Senior Rails Engineer", location: "Yogyakarta, Indonesia", hourly_rate_usd: 55,
    skills: [ "Ruby", "Rails", "PostgreSQL", "Hotwire", "AWS", "RSpec" ],
    bio: "Senior Rails engineer with a track record of dependable marketplace and ecommerce delivery, from PostgreSQL performance tuning to Hotwire-driven interfaces and AWS deployments."
  )
  find_or_create_freelancer_profile(
    user: users[:grace], title: "Rails & Billing Consultant", location: "Portland, USA", hourly_rate_usd: 62,
    skills: [ "Ruby", "Rails", "Stripe", "PostgreSQL", "Billing" ],
    bio: "Rails consultant who understands delivery from both client and freelancer perspectives, focused on subscription billing."
  )
  find_or_create_freelancer_profile(
    user: users[:olivia], title: "Rails & Hotwire Developer", location: "Nashville, USA", hourly_rate_usd: 48,
    skills: [ "Ruby", "Rails", "Hotwire", "Stimulus", "Tailwind CSS" ],
    bio: "Rails developer building responsive Hotwire applications without unnecessary frontend complexity."
  )
  find_or_create_freelancer_profile(
    user: users[:daniel], title: "Rails API Engineer", location: "Raleigh, USA", hourly_rate_usd: 52,
    skills: [ "Ruby", "Rails", "REST APIs", "PostgreSQL", "Redis" ],
    bio: "Backend engineer focused on Rails APIs, database design, and operational reliability."
  )
  find_or_create_freelancer_profile(
    user: users[:sophia], title: "Rails Platform Engineer", location: "Seattle, USA", hourly_rate_usd: 58,
    skills: [ "Ruby", "Rails", "AWS", "Docker", "CI/CD" ],
    bio: "Platform-minded Rails engineer experienced with modernization projects and production deployments."
  )
  find_or_create_freelancer_profile(
    user: users[:ethan], title: "Rails & Shopify Developer", location: "Phoenix, USA", hourly_rate_usd: 68,
    skills: [ "Ruby", "Rails", "Shopify", "PostgreSQL" ],
    bio: "Full-stack Rails developer connecting Shopify commerce data to internal systems."
  )
  find_or_create_freelancer_profile(
    user: users[:noah], title: "Rails Backend & Sidekiq Developer", location: "Boston, USA", hourly_rate_usd: 72,
    skills: [ "Ruby", "Rails", "Sidekiq", "RSpec", "PostgreSQL" ],
    bio: "Backend developer experienced in Rails upgrades, background processing, and test suite stabilization."
  )
  find_or_create_freelancer_profile(
    user: users[:ava], title: "Rails Developer", location: "Charlotte, USA", hourly_rate_usd: 45,
    skills: [ "Ruby", "Rails", "PostgreSQL" ],
    bio: "Rails developer building practical products and internal tools for small teams."
  )

  # -- The reserved live-demo job: no proposals, no shortlist, no contract ----
  jobs[:live_demo] = find_or_create_job(
    client: users[:emily], title: "Build Rails Marketplace Features",
    description: "Extend an existing Rails marketplace with new workflow features, tune PostgreSQL query performance, add Hotwire-driven UI updates, and keep the automated test suite green throughout.",
    budget_usd: 4_000, skills: [ "Ruby", "Rails", "PostgreSQL", "Hotwire", "RSpec" ], status: :open
  )

  # This job must always come back to a clean slate so `bin/rails db:seed` is
  # safe to rerun against a live/demoed deployment. Only THIS job's contract,
  # proposals, and shortlist entries are cleared -- nothing else in the
  # marketplace is touched.
  jobs[:live_demo].contract&.destroy!
  jobs[:live_demo].proposals.destroy_all
  jobs[:live_demo].shortlists.destroy_all
  jobs[:live_demo].update!(status: :open)

  # -- Other open jobs (kept open all the way through the seed) --------------
  jobs[:rails8_upgrade] = find_or_create_job(
    client: users[:james], title: "Upgrade Rails Application to Rails 8",
    description: "Upgrade a production operations application to Rails 8, resolve deprecations, and keep the existing test suite stable.",
    budget_usd: 4_500, skills: [ "Ruby", "Rails", "RSpec", "PostgreSQL" ], status: :open
  )
  jobs[:checkout_tuning] = find_or_create_job(
    client: users[:michael], title: "PostgreSQL Checkout Performance Tuning",
    description: "Profile and improve slow checkout queries in a mature Rails ecommerce application.",
    budget_usd: 3_200, skills: [ "Ruby", "Rails", "PostgreSQL" ], status: :open
  )
  jobs[:hotwire_dashboard_open] = find_or_create_job(
    client: users[:sarah], title: "Build Hotwire Operations Dashboard",
    description: "Build a responsive operations dashboard using Rails, Hotwire, and accessible server-rendered components.",
    budget_usd: 3_800, skills: [ "Ruby", "Rails", "Hotwire", "Stimulus" ], status: :open
  )
  jobs[:api_modernization_open] = find_or_create_job(
    client: users[:grace], title: "Rails API Modernization",
    description: "Modernize an internal Rails API, improve test coverage, and reduce deployment risk.",
    budget_usd: 3_600, skills: [ "Ruby", "Rails", "PostgreSQL", "REST APIs" ], status: :open
  )
  jobs[:shopify_integration_open] = find_or_create_job(
    client: users[:michael], title: "Shopify Integration for Rails Backend",
    description: "Connect Shopify order data to an existing Rails reporting backend with reliable synchronization.",
    budget_usd: 2_600, skills: [ "Ruby", "Rails", "Shopify", "PostgreSQL" ], status: :open
  )

  # -- Draft job (never appears in public /jobs) ------------------------------
  jobs[:aws_cleanup_draft] = find_or_create_job(
    client: users[:sarah], title: "AWS Deployment Cleanup",
    description: "Simplify a Rails deployment on AWS, document the release process, and remove obsolete infrastructure.",
    budget_usd: 1_800, skills: [ "Rails", "AWS", "Docker", "CI/CD" ], status: :draft
  )

  # -- Historical jobs: declared :open so proposals validate, then closed by
  # find_or_create_contract below. Final status is verified after the seed.
  jobs[:checkout_perf_historical] = find_or_create_job(
    client: users[:emily], title: "Checkout Performance Optimization",
    description: "Profile and improve slow checkout queries in a mature Rails ecommerce application.",
    budget_usd: 2_800, skills: [ "Ruby", "Rails", "PostgreSQL" ], status: :open
  )
  jobs[:legacy_ecommerce_historical] = find_or_create_job(
    client: users[:emily], title: "Legacy Ecommerce Rails Upgrade",
    description: "Modernize a legacy Rails storefront while preserving checkout behavior and historical order data.",
    budget_usd: 3_100, skills: [ "Ruby", "Rails", "PostgreSQL", "AWS" ], status: :open
  )
  jobs[:inventory_migration_historical] = find_or_create_job(
    client: users[:michael], title: "Ecommerce Inventory Data Migration",
    description: "Execute a reliable inventory migration with reconciliation reports and rollback steps.",
    budget_usd: 3_300, skills: [ "Ruby", "Rails", "PostgreSQL", "Data Migration" ], status: :open
  )
  jobs[:billing_reliability_historical] = find_or_create_job(
    client: users[:sarah], title: "Subscription Billing Reliability Improvements",
    description: "Harden subscription billing workflows, improve retry behavior, and document operational recovery steps.",
    budget_usd: 2_900, skills: [ "Ruby", "Rails", "PostgreSQL", "Stripe" ], status: :open
  )
  jobs[:growth_dashboard_historical] = find_or_create_job(
    client: users[:michael], title: "Growth Analytics Admin Dashboard",
    description: "Build an internal Rails and Hotwire dashboard for acquisition and retention reporting.",
    budget_usd: 2_400, skills: [ "Ruby", "Rails", "Hotwire", "JavaScript" ], status: :open
  )
  jobs[:legacy_logistics_api_historical] = find_or_create_job(
    client: users[:james], title: "Legacy Logistics API Modernization",
    description: "Modernize a logistics API, improve test coverage, and reduce deployment risk.",
    budget_usd: 3_900, skills: [ "Ruby", "Rails", "PostgreSQL", "APIs" ], status: :open
  )
  jobs[:marketplace_backend_historical] = find_or_create_job(
    client: users[:grace], title: "Marketplace Backend Improvements",
    description: "Improve marketplace domain workflows, query performance, and automated coverage in an established Rails application.",
    budget_usd: 3_700, skills: [ "Ruby", "Rails", "PostgreSQL", "RSpec" ], status: :open
  )
  jobs[:marketplace_analytics_historical] = find_or_create_job(
    client: users[:grace], title: "Marketplace Analytics Rebuild",
    description: "Rebuild marketplace analytics reporting with reliable Rails background processing.",
    budget_usd: 3_500, skills: [ "Ruby", "Rails", "Sidekiq", "PostgreSQL" ], status: :open
  )

  # -- Proposals on other open jobs: pending/withdrawn only, never accepted --
  # Kurnia intentionally has none of these, so his first proposal is the one
  # created live during the WebMCP demo.
  find_or_create_proposal(job: jobs[:rails8_upgrade], freelancer: users[:daniel], amount_usd: 4_100, status: :pending,
    message: "I can handle the framework upgrade with particular attention to API and PostgreSQL compatibility.")
  find_or_create_proposal(job: jobs[:rails8_upgrade], freelancer: users[:sophia], amount_usd: 4_300, status: :pending,
    message: "I will audit dependencies, complete the Rails 8 upgrade in stages, and keep the test suite stable.")
  find_or_create_proposal(job: jobs[:rails8_upgrade], freelancer: users[:noah], amount_usd: 3_900, status: :withdrawn,
    message: "I can perform the upgrade and strengthen coverage around background jobs and data workflows.")

  find_or_create_proposal(job: jobs[:checkout_tuning], freelancer: users[:olivia], amount_usd: 2_900, status: :pending,
    message: "I can profile checkout queries and ship a polished, fast dashboard for reviewing the results.")
  find_or_create_proposal(job: jobs[:checkout_tuning], freelancer: users[:ava], amount_usd: 2_800, status: :pending,
    message: "I can investigate slow queries and improve checkout response time.")

  find_or_create_proposal(job: jobs[:hotwire_dashboard_open], freelancer: users[:grace], amount_usd: 3_500, status: :pending,
    message: "I can build this dashboard with Rails, Hotwire, and clear billing metrics.")
  find_or_create_proposal(job: jobs[:hotwire_dashboard_open], freelancer: users[:ethan], amount_usd: 3_600, status: :pending,
    message: "I can deliver a responsive Hotwire dashboard integrated with the existing data sources.")

  find_or_create_proposal(job: jobs[:api_modernization_open], freelancer: users[:sophia], amount_usd: 3_300, status: :pending,
    message: "I can modernize the API with a focus on database boundaries and deployment safety.")
  find_or_create_proposal(job: jobs[:api_modernization_open], freelancer: users[:daniel], amount_usd: 3_200, status: :withdrawn,
    message: "I can refactor the API and improve automated coverage around risky integrations.")

  find_or_create_proposal(job: jobs[:shopify_integration_open], freelancer: users[:ava], amount_usd: 2_400, status: :pending,
    message: "I can build resilient Shopify synchronization with tested reconciliation.")

  # -- Historical proposals: exactly one accepted proposal per contracted job
  find_or_create_proposal(job: jobs[:checkout_perf_historical], freelancer: users[:kurnia], amount_usd: 2_800, status: :accepted,
    message: "I will profile checkout queries, add targeted indexes, and verify measurable improvements.")
  find_or_create_proposal(job: jobs[:checkout_perf_historical], freelancer: users[:ava], amount_usd: 2_700, status: :rejected,
    message: "I can investigate slow queries and improve checkout API response time.")

  find_or_create_proposal(job: jobs[:legacy_ecommerce_historical], freelancer: users[:sophia], amount_usd: 3_100, status: :accepted,
    message: "I can modernize this codebase carefully and preserve historical order behavior.")
  find_or_create_proposal(job: jobs[:legacy_ecommerce_historical], freelancer: users[:olivia], amount_usd: 3_000, status: :rejected,
    message: "I can coordinate the Rails, PostgreSQL, and deployment modernization with a low-risk rollout.")

  find_or_create_proposal(job: jobs[:inventory_migration_historical], freelancer: users[:kurnia], amount_usd: 3_300, status: :accepted,
    message: "I can plan the migration, build reconciliation tooling, and run a controlled cutover.")
  find_or_create_proposal(job: jobs[:inventory_migration_historical], freelancer: users[:daniel], amount_usd: 3_200, status: :rejected,
    message: "I can build migration scripts and comprehensive reconciliation and rollback coverage.")

  find_or_create_proposal(job: jobs[:billing_reliability_historical], freelancer: users[:daniel], amount_usd: 2_900, status: :accepted,
    message: "I can harden billing failure states and provide practical operational documentation.")
  find_or_create_proposal(job: jobs[:billing_reliability_historical], freelancer: users[:ava], amount_usd: 2_850, status: :rejected,
    message: "I can improve billing reliability and the experience around failed and retried payments.")

  find_or_create_proposal(job: jobs[:growth_dashboard_historical], freelancer: users[:olivia], amount_usd: 2_400, status: :accepted,
    message: "I can build the dashboard with Rails and Hotwire and integrate the existing analytics tables.")
  find_or_create_proposal(job: jobs[:growth_dashboard_historical], freelancer: users[:ethan], amount_usd: 2_600, status: :rejected,
    message: "I can build a polished dashboard with fast server-rendered interactions.")

  find_or_create_proposal(job: jobs[:legacy_logistics_api_historical], freelancer: users[:ethan], amount_usd: 3_900, status: :accepted,
    message: "I can modernize the API, containerize deployment, and improve coverage around risky integrations.")
  find_or_create_proposal(job: jobs[:legacy_logistics_api_historical], freelancer: users[:noah], amount_usd: 3_800, status: :rejected,
    message: "I can refactor the API with a focus on database boundaries, tests, and deployment safety.")

  find_or_create_proposal(job: jobs[:marketplace_backend_historical], freelancer: users[:kurnia], amount_usd: 3_700, status: :accepted,
    message: "I can strengthen marketplace workflows, remove query bottlenecks, and expand test coverage.")
  find_or_create_proposal(job: jobs[:marketplace_backend_historical], freelancer: users[:sophia], amount_usd: 3_600, status: :rejected,
    message: "I can improve the backend and deployment pipeline with an emphasis on reliability.")

  find_or_create_proposal(job: jobs[:marketplace_analytics_historical], freelancer: users[:noah], amount_usd: 3_500, status: :accepted,
    message: "I can rebuild analytics reporting on reliable Sidekiq background processing.")
  find_or_create_proposal(job: jobs[:marketplace_analytics_historical], freelancer: users[:ethan], amount_usd: 3_400, status: :rejected,
    message: "I can rebuild the reporting pipeline with a focus on Shopify data sources.")

  # -- Contracts: six completed (closed historical jobs) + one active --------
  contract_checkout = find_or_create_contract(job: jobs[:checkout_perf_historical], freelancer: users[:kurnia],
    status: :completed, started_at: "2025-10-06 09:00", completed_at: "2025-11-14 16:00")
  contract_legacy_ecommerce = find_or_create_contract(job: jobs[:legacy_ecommerce_historical], freelancer: users[:sophia],
    status: :completed, started_at: "2025-11-24 09:00", completed_at: "2026-01-09 15:00")
  contract_inventory = find_or_create_contract(job: jobs[:inventory_migration_historical], freelancer: users[:kurnia],
    status: :completed, started_at: "2026-01-19 09:00", completed_at: "2026-02-27 17:00")
  contract_billing = find_or_create_contract(job: jobs[:billing_reliability_historical], freelancer: users[:daniel],
    status: :completed, started_at: "2026-03-09 09:00", completed_at: "2026-04-10 14:00")
  contract_growth = find_or_create_contract(job: jobs[:growth_dashboard_historical], freelancer: users[:olivia],
    status: :completed, started_at: "2026-04-20 09:00", completed_at: "2026-05-29 18:00")
  contract_logistics_api = find_or_create_contract(job: jobs[:legacy_logistics_api_historical], freelancer: users[:ethan],
    status: :completed, started_at: "2026-06-01 09:00", completed_at: "2026-07-03 15:00")
  contract_marketplace_backend = find_or_create_contract(job: jobs[:marketplace_backend_historical], freelancer: users[:kurnia],
    status: :completed, started_at: "2026-07-13 09:00", completed_at: "2026-08-14 16:00")
  find_or_create_contract(job: jobs[:marketplace_analytics_historical], freelancer: users[:noah],
    status: :active, started_at: "2026-08-17 09:00", completed_at: nil)

  # -- Reviews: varied ratings, both directions -- nobody is flawless --------
  find_or_create_review(contract: contract_checkout, reviewer: users[:emily], reviewee: users[:kurnia], rating: 5,
    body: "Excellent Rails engineer. The PostgreSQL improvements were measurable, and communication stayed clear throughout.")
  find_or_create_review(contract: contract_checkout, reviewer: users[:kurnia], reviewee: users[:emily], rating: 5,
    body: "Clear scope, fast feedback, and payment was handled immediately after delivery.")

  find_or_create_review(contract: contract_legacy_ecommerce, reviewer: users[:emily], reviewee: users[:sophia], rating: 5,
    body: "Reliable migration work and careful attention to checkout behavior throughout.")
  find_or_create_review(contract: contract_legacy_ecommerce, reviewer: users[:sophia], reviewee: users[:emily], rating: 4,
    body: "Clear requirements and responsive feedback; final approval took a little longer than expected.")

  find_or_create_review(contract: contract_inventory, reviewer: users[:michael], reviewee: users[:kurnia], rating: 5,
    body: "Outstanding migration planning and rollback safety. Would hire again without hesitation.")
  find_or_create_review(contract: contract_inventory, reviewer: users[:kurnia], reviewee: users[:michael], rating: 4,
    body: "Good client with clear requirements, though the timeline shifted once mid-project.")

  find_or_create_review(contract: contract_billing, reviewer: users[:sarah], reviewee: users[:daniel], rating: 4,
    body: "Solid reliability improvements, well documented, delivered on schedule.")
  find_or_create_review(contract: contract_billing, reviewer: users[:daniel], reviewee: users[:sarah], rating: 3,
    body: "Payment was prompt, but the scope changed a few times mid-project.")

  find_or_create_review(contract: contract_growth, reviewer: users[:michael], reviewee: users[:olivia], rating: 3,
    body: "Dashboard works well, but the final milestone slipped by several days near the end.")
  find_or_create_review(contract: contract_growth, reviewer: users[:olivia], reviewee: users[:michael], rating: 3,
    body: "Project completed successfully, though requirements shifted after work started.")

  find_or_create_review(contract: contract_logistics_api, reviewer: users[:james], reviewee: users[:ethan], rating: 4,
    body: "Strong API modernization work with good communication throughout delivery.")
  find_or_create_review(contract: contract_logistics_api, reviewer: users[:ethan], reviewee: users[:james], rating: 3,
    body: "Technical goals were clear, but approvals were sometimes slow.")

  find_or_create_review(contract: contract_marketplace_backend, reviewer: users[:grace], reviewee: users[:kurnia], rating: 4,
    body: "Great technical work on the marketplace backend; a few follow-up questions after delivery.")
  find_or_create_review(contract: contract_marketplace_backend, reviewer: users[:kurnia], reviewee: users[:grace], rating: 5,
    body: "Clear priorities, quick answers, and prompt approval after delivery.")

  # -- Shortlists on other jobs -- Emily's live-demo job stays untouched -----
  find_or_create_shortlist(job: jobs[:rails8_upgrade], freelancer: users[:daniel])
  find_or_create_shortlist(job: jobs[:rails8_upgrade], freelancer: users[:sophia])
  find_or_create_shortlist(job: jobs[:checkout_tuning], freelancer: users[:olivia])
end

# ---------------------------------------------------------------------------
# Post-seed verification: the historical-contract loop above closes jobs, so
# we verify FINAL state here rather than trusting the initial declarations.
# ---------------------------------------------------------------------------

emily = users.fetch(:emily)
kurnia = users.fetch(:kurnia)
live_demo_job = jobs.fetch(:live_demo)

raise "Seed error: Emily is missing a ClientProfile" unless emily.client_profile
raise "Seed error: Kurnia is missing a FreelancerProfile" unless kurnia.freelancer_profile
raise "Seed error: live demo job is not owned by Emily" unless live_demo_job.client == emily
raise "Seed error: live demo job is not open" unless live_demo_job.reload.open?
raise "Seed error: live demo job has a contract" if live_demo_job.contract.present?
raise "Seed error: Kurnia already has a proposal for the live demo job" if live_demo_job.proposals.exists?(freelancer: kurnia)
raise "Seed error: live demo job already has shortlist entries" if live_demo_job.shortlists.exists?

candidate_pool = FreelancerProfile.includes(:user)
  .where("freelancer_profiles.skills @> ARRAY[?]::varchar[]", "Rails")
  .where(hourly_rate_cents: ...usd_cents(60))
  .to_a
trust_evidence = FreelancerProfile.trust_evidence_for(candidate_pool.map(&:user_id))
candidates_with_evidence = candidate_pool.select { |profile| trust_evidence.fetch(profile.user_id)[:review_count] > 0 }
raise "Seed error: fewer than 3 trustworthy Rails freelancers under $60/hour" if candidates_with_evidence.size < 3

draft_proposal = live_demo_job.proposals.new(freelancer: kurnia, amount_cents: usd_cents(3_200), message: "Demo verification only.", status: :draft)
raise "Seed error: Kurnia cannot validly draft a proposal for the live demo job (#{draft_proposal.errors.full_messages.to_sentence})" unless draft_proposal.valid?

job_status_counts = Job.group(:status).count
kurnia_evidence = FreelancerProfile.trust_evidence_for([ kurnia.id ]).fetch(kurnia.id)
emily_completed_contracts = emily.client_contracts.completed.count
emily_reviews = Review.for_client_role(emily)

puts <<~SUMMARY
  Gigoo demo data ready.

  Client demo:
  emily@gigoo.test / password

  Freelancer demo:
  kurnia@gigoo.test / password

  Live demo job:
  #{live_demo_job.title}
  $#{live_demo_job.budget.to_i}
  #{live_demo_job.status.capitalize}
  #{live_demo_job.shortlists.count} shortlist entries
  #{live_demo_job.proposals.exists?(freelancer: kurnia) ? "Kurnia has a proposal (unexpected)" : "No Kurnia proposal"}

  Rails candidates under $60/hour (with trust evidence):
  #{candidates_with_evidence.map { |p| "- #{p.user.name}: $#{p.hourly_rate.to_i}/hr, avg #{trust_evidence.fetch(p.user_id)[:average_rating]&.round(1)}, #{trust_evidence.fetch(p.user_id)[:review_count]} reviews" }.join("\n")}

  Jobs by status:
  #{job_status_counts.map { |status, count| "#{count} #{status}" }.join("\n")}

  Kurnia trust evidence: avg #{kurnia_evidence[:average_rating]&.round(1)}, #{kurnia_evidence[:review_count]} reviews, #{kurnia_evidence[:completed_contract_count]} completed contracts
  Emily trust evidence: avg #{emily_reviews.average(:rating)&.round(1)}, #{emily_reviews.count} reviews, #{emily_completed_contracts} completed contracts

  Total: #{User.count} users, #{ClientProfile.count} client profiles, #{FreelancerProfile.count} freelancer profiles,
  #{Job.count} jobs, #{Proposal.count} proposals, #{Contract.count} contracts, #{Review.count} reviews, #{Shortlist.count} shortlists.
SUMMARY
