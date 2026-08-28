demo_password = "password"

users = {}
client_profiles = {}
freelancer_profiles = {}
jobs = {}
proposals = []
contracts = []
reviews = []
shortlists = []

user_data = {
  alice: [ "Alice", "Johnson", "alice@gigoo.test" ],
  mark: [ "Mark", "Wilson", "mark@gigoo.test" ],
  priya: [ "Priya", "Shah", "priya@gigoo.test" ],
  omar: [ "Omar", "Haddad", "omar@gigoo.test" ],
  chloe: [ "Chloe", "Martin", "chloe@gigoo.test" ],
  kurnia: [ "Kurnia", "Muhamad", "kurnia@gigoo.test" ],
  sarah: [ "Sarah", "Chen", "sarah@gigoo.test" ],
  tom: [ "Tom", "Brown", "tom@gigoo.test" ],
  maya: [ "Maya", "Rodriguez", "maya@gigoo.test" ],
  diego: [ "Diego", "Alvarez", "diego@gigoo.test" ],
  aisha: [ "Aisha", "Patel", "aisha@gigoo.test" ],
  liam: [ "Liam", "O'Connor", "liam@gigoo.test" ],
  nina: [ "Nina", "Petrov", "nina@gigoo.test" ]
}

client_profile_data = {
  alice: [ "Northstar Commerce", "Amsterdam, Netherlands", true, "International ecommerce brands investing in reliable long-term platform improvements." ],
  mark: [ "GrowthForge", "Austin, USA", true, "Analytics and acquisition tools for growing online businesses." ],
  priya: [ "Meridian Health Systems", "Toronto, Canada", true, "Healthcare operations software with an emphasis on dependable delivery." ],
  omar: [ "Atlas Systems", "Dubai, UAE", true, "Operational software modernization for logistics teams across the Middle East." ],
  chloe: [ "BrightPath Studio", "Melbourne, Australia", false, "Subscription products for independent education businesses." ]
}

freelancer_profile_data = {
  kurnia: [ "Senior Rails Engineer", "Yogyakarta, Indonesia", 6_500, [ "Ruby", "Rails", "PostgreSQL", "Hotwire", "AWS" ], "Senior Rails engineer focused on ecommerce migrations, PostgreSQL performance, and dependable production delivery." ],
  sarah: [ "Rails & Platform Engineer", "Singapore", 7_000, [ "Ruby", "Rails", "PostgreSQL", "Docker", "AWS" ], "Platform-minded Rails engineer experienced with modernization projects, deployment systems, and high-traffic applications." ],
  tom: [ "Full-stack Rails Developer", "London, UK", 4_500, [ "Ruby", "Rails", "JavaScript", "Hotwire", "PostgreSQL" ], "Full-stack developer building practical Rails products and internal tools for small teams." ],
  maya: [ "Product-focused Rails Engineer", "Mexico City, Mexico", 5_500, [ "Ruby", "Rails", "Hotwire", "Tailwind CSS", "Stripe" ], "Product engineer specializing in polished server-rendered Rails experiences and payment workflows." ],
  diego: [ "Rails API Engineer", "Madrid, Spain", 5_000, [ "Ruby", "Rails", "PostgreSQL", "REST APIs", "Redis" ], "Backend engineer focused on Rails APIs, database design, and operational reliability." ],
  aisha: [ "Hotwire Application Developer", "Bengaluru, India", 4_800, [ "Ruby", "Rails", "Hotwire", "Stimulus", "Tailwind CSS" ], "Rails developer building responsive Hotwire applications without unnecessary frontend complexity." ],
  liam: [ "Rails Infrastructure Consultant", "Dublin, Ireland", 6_000, [ "Ruby", "Rails", "AWS", "Docker", "CI/CD" ], "Infrastructure consultant helping Rails teams simplify deployments, observability, and continuous delivery." ],
  nina: [ "Rails Backend Developer", "Warsaw, Poland", 4_200, [ "Ruby", "Rails", "PostgreSQL", "Sidekiq", "RSpec" ], "Backend developer experienced in Rails upgrades, background processing, and test suite stabilization." ],
  omar: [ "Product-minded Rails Consultant", "Dubai, UAE", 5_800, [ "Ruby", "Rails", "PostgreSQL", "Product Strategy", "APIs" ], "Rails consultant who understands delivery from both client and freelancer perspectives." ],
  chloe: [ "Full-stack Rails Product Engineer", "Melbourne, Australia", 5_200, [ "Ruby", "Rails", "Hotwire", "UX", "PostgreSQL" ], "Full-stack Rails engineer with a strong product design sensibility and experience running client projects." ]
}

job_data = {
  ecommerce_migration: [ :alice, "Rails Ecommerce Migration", "Migrate an existing ecommerce application to modern Rails, improve PostgreSQL performance, and clean up deployment.", 300_000, [ "Ruby", "Rails", "PostgreSQL", "AWS" ], :open ],
  rails_8_upgrade: [ :priya, "Upgrade Rails 7 Application to Rails 8", "Upgrade a production operations application to Rails 8, resolve deprecations, and keep the existing test suite stable.", 450_000, [ "Ruby", "Rails", "RSpec", "PostgreSQL" ], :open ],
  aws_cleanup: [ :mark, "AWS Deployment Cleanup", "Simplify a Rails deployment on AWS, document the release process, and remove obsolete infrastructure.", 180_000, [ "Rails", "AWS", "Docker", "CI/CD" ], :draft ],
  checkout_performance: [ :alice, "Fix PostgreSQL Checkout Performance Bottlenecks", "Profile and improve slow checkout queries in a mature Rails ecommerce application.", 240_000, [ "Ruby", "Rails", "PostgreSQL" ], :open ],
  legacy_ecommerce: [ :alice, "Legacy Ecommerce Rails Upgrade", "Modernize a legacy Rails storefront while preserving checkout behavior and historical order data.", 280_000, [ "Ruby", "Rails", "PostgreSQL", "AWS" ], :open ],
  growth_dashboard: [ :mark, "Growth Analytics Admin Dashboard", "Build an internal Rails and Hotwire dashboard for acquisition and retention reporting.", 200_000, [ "Ruby", "Rails", "Hotwire", "JavaScript" ], :open ],
  legacy_api: [ :omar, "Legacy Rails API Modernization", "Modernize a logistics API, improve test coverage, and reduce deployment risk.", 360_000, [ "Ruby", "Rails", "PostgreSQL", "APIs" ], :open ],
  shopify_integration: [ :mark, "Shopify Integration for Rails Backend", "Connect Shopify order data to an existing Rails reporting backend with reliable synchronization.", 260_000, [ "Ruby", "Rails", "Shopify", "PostgreSQL" ], :open ],
  inventory_migration: [ :priya, "Ecommerce Inventory Data Migration", "Execute a reliable inventory migration with reconciliation reports and rollback steps.", 300_000, [ "Ruby", "Rails", "PostgreSQL", "Data Migration" ], :open ],
  billing_reliability: [ :chloe, "Subscription Billing Reliability Improvements", "Harden subscription billing workflows, improve retry behavior, and document operational recovery steps.", 250_000, [ "Ruby", "Rails", "PostgreSQL", "Stripe" ], :open ],
  hotwire_dashboard: [ :priya, "Build Hotwire Operations Dashboard", "Build a responsive operations dashboard using Rails, Hotwire, and accessible server-rendered components.", 380_000, [ "Ruby", "Rails", "Hotwire", "Stimulus" ], :open ],
  marketplace_backend: [ :alice, "Marketplace Backend Improvements", "Improve marketplace domain workflows, query performance, and automated coverage in an established Rails application.", 450_000, [ "Ruby", "Rails", "PostgreSQL", "RSpec" ], :open ]
}

proposal_data = [
  [ :ecommerce_migration, :kurnia, 280_000, :pending, "I can lead the Rails migration, profile PostgreSQL, and leave the AWS deployment simpler and documented." ],
  [ :ecommerce_migration, :sarah, 320_000, :pending, "I have completed similar platform migrations and can coordinate application, database, and deployment changes." ],
  [ :ecommerce_migration, :tom, 240_000, :pending, "I can modernize the application while focusing first on checkout and deployment risks." ],
  [ :ecommerce_migration, :maya, 275_000, :pending, "I can deliver the migration incrementally while keeping customer-facing behavior stable." ],
  [ :rails_8_upgrade, :kurnia, 420_000, :pending, "I will audit dependencies, complete the Rails 8 upgrade in stages, and keep the RSpec suite green." ],
  [ :rails_8_upgrade, :diego, 390_000, :pending, "I can handle the framework upgrade with particular attention to API and PostgreSQL compatibility." ],
  [ :rails_8_upgrade, :aisha, 405_000, :pending, "I can upgrade the application and verify existing Hotwire interactions remain stable." ],
  [ :rails_8_upgrade, :nina, 360_000, :withdrawn, "I can perform the upgrade and strengthen coverage around background jobs and data workflows." ],
  [ :checkout_performance, :kurnia, 220_000, :accepted, "I will profile checkout queries, add targeted indexes, and verify measurable improvements." ],
  [ :checkout_performance, :diego, 210_000, :rejected, "I can investigate slow queries and improve checkout API response time." ],
  [ :legacy_ecommerce, :kurnia, 265_000, :accepted, "I can modernize this codebase carefully and preserve historical order behavior." ],
  [ :legacy_ecommerce, :sarah, 290_000, :rejected, "I can coordinate the Rails, PostgreSQL, and deployment modernization with a low-risk rollout." ],
  [ :growth_dashboard, :tom, 180_000, :accepted, "I can build the dashboard with Rails and Hotwire and integrate the existing analytics tables." ],
  [ :growth_dashboard, :maya, 195_000, :rejected, "I can build a polished dashboard with fast server-rendered interactions." ],
  [ :legacy_api, :sarah, 340_000, :accepted, "I can modernize the API, containerize deployment, and improve coverage around risky integrations." ],
  [ :legacy_api, :diego, 320_000, :rejected, "I can refactor the API with a focus on database boundaries, tests, and deployment safety." ],
  [ :shopify_integration, :sarah, 245_000, :accepted, "I can build resilient Shopify synchronization and document recovery for failed imports." ],
  [ :shopify_integration, :maya, 230_000, :rejected, "I can implement Shopify synchronization with tested reconciliation and operational visibility." ],
  [ :inventory_migration, :sarah, 275_000, :accepted, "I can plan the migration, build reconciliation tooling, and run a controlled cutover." ],
  [ :inventory_migration, :nina, 250_000, :rejected, "I can build migration scripts and comprehensive reconciliation and rollback coverage." ],
  [ :billing_reliability, :omar, 235_000, :accepted, "I can harden billing failure states and provide practical operational documentation." ],
  [ :billing_reliability, :maya, 240_000, :rejected, "I can improve billing reliability and the experience around failed and retried payments." ],
  [ :hotwire_dashboard, :kurnia, 350_000, :accepted, "I can build this with conventional Rails and Hotwire while keeping queries maintainable." ],
  [ :hotwire_dashboard, :aisha, 330_000, :rejected, "I can deliver accessible Hotwire interactions with focused Stimulus controllers." ],
  [ :marketplace_backend, :sarah, 420_000, :accepted, "I can strengthen marketplace workflows, remove query bottlenecks, and expand RSpec coverage." ],
  [ :marketplace_backend, :liam, 400_000, :rejected, "I can improve the backend and deployment pipeline with an emphasis on reliability." ]
]

contract_data = [
  [ :checkout_performance, :kurnia, :completed, "2025-02-03 09:00", "2025-03-01 16:00" ],
  [ :legacy_ecommerce, :kurnia, :completed, "2025-04-07 09:00", "2025-05-16 15:00" ],
  [ :growth_dashboard, :tom, :completed, "2025-06-02 09:00", "2025-07-11 18:00" ],
  [ :legacy_api, :sarah, :completed, "2025-08-04 09:00", "2025-09-12 14:00" ],
  [ :shopify_integration, :sarah, :completed, "2025-10-06 09:00", "2025-11-14 17:00" ],
  [ :inventory_migration, :sarah, :completed, "2026-01-12 09:00", "2026-02-20 16:00" ],
  [ :billing_reliability, :omar, :completed, "2026-03-09 09:00", "2026-04-03 15:00" ],
  [ :hotwire_dashboard, :kurnia, :active, "2026-07-13 09:00", nil ],
  [ :marketplace_backend, :sarah, :active, "2026-08-10 09:00", nil ]
]

review_data = {
  checkout_performance: [
    [ :alice, :kurnia, 5, "Excellent Rails engineer. The PostgreSQL improvements were measurable, and communication stayed clear throughout delivery." ],
    [ :kurnia, :alice, 5, "Clear scope, fast feedback, and payment was handled immediately after delivery." ]
  ],
  legacy_ecommerce: [
    [ :alice, :kurnia, 5, "Strong Rails knowledge and handled a complicated ecommerce migration reliably. Delivery was on time." ],
    [ :kurnia, :alice, 5, "A professional client with realistic expectations, quick decisions, and good communication." ]
  ],
  growth_dashboard: [
    [ :mark, :tom, 3, "The implementation quality was good, but the final milestone arrived several days later than agreed. Communication became slow near delivery." ],
    [ :tom, :mark, 3, "The project was completed successfully, but the scope changed repeatedly and several requirements were unclear after work started." ]
  ],
  legacy_api: [
    [ :omar, :sarah, 5, "Strong platform engineering and clear communication. The Rails API modernization was delivered reliably." ],
    [ :sarah, :omar, 4, "The technical goals were clear and feedback was thoughtful, though final approval took a little longer than expected." ]
  ],
  shopify_integration: [
    [ :mark, :sarah, 4, "Solid Rails and Shopify work with good technical judgment. One integration edge case needed a follow-up." ],
    [ :sarah, :mark, 3, "Payment was completed, though the scope changed several times and approvals were often slow." ]
  ],
  inventory_migration: [
    [ :priya, :sarah, 5, "Excellent migration planning, reliable delivery, and strong PostgreSQL knowledge." ],
    [ :sarah, :priya, 5, "Clear requirements, quick feedback, and a smooth approval process." ]
  ],
  billing_reliability: [
    [ :chloe, :omar, 5, "Omar communicated clearly and delivered the billing reliability improvements on schedule." ],
    [ :omar, :chloe, 5, "Chloe provided clear priorities, quick answers, and prompt approval after delivery." ]
  ]
}

ApplicationRecord.transaction do
  user_data.each do |key, (first_name, last_name, email_address)|
    user = User.find_or_initialize_by(email_address: email_address)
    user.assign_attributes(
      first_name: first_name,
      last_name: last_name,
      role: :member,
      password: demo_password,
      password_confirmation: demo_password
    )
    user.save!
    users[key] = user
  end

  client_profile_data.each do |key, (company_name, location, payment_verified, bio)|
    profile = ClientProfile.find_or_initialize_by(user: users.fetch(key))
    profile.update!(company_name: company_name, location: location, payment_verified: payment_verified, bio: bio)
    client_profiles[key] = profile
  end

  freelancer_profile_data.each do |key, (title, location, hourly_rate_cents, skills, bio)|
    profile = FreelancerProfile.find_or_initialize_by(user: users.fetch(key))
    profile.update!(title: title, location: location, hourly_rate_cents: hourly_rate_cents, skills: skills, bio: bio)
    freelancer_profiles[key] = profile
  end

  job_data.each do |key, (client_key, title, description, budget_cents, skills, status)|
    job = Job.find_or_initialize_by(client: users.fetch(client_key), title: title)
    job.update!(description: description, budget_cents: budget_cents, skills: skills, status: status)
    jobs[key] = job
  end

  proposal_data.each do |job_key, freelancer_key, amount_cents, status, message|
    proposal = Proposal.find_or_initialize_by(job: jobs.fetch(job_key), freelancer: users.fetch(freelancer_key))
    proposal.assign_attributes(amount_cents: amount_cents, message: message, status: :pending)
    proposal.save!
    proposal.update!(status: status) unless proposal.status == status.to_s
    proposals << proposal
  end

  contract_data.each do |job_key, freelancer_key, status, started_at, completed_at|
    job = jobs.fetch(job_key)
    proposal = Proposal.find_by!(job: job, freelancer: users.fetch(freelancer_key))
    contract = Contract.find_or_initialize_by(job: job)
    contract.update!(
      client: job.client,
      freelancer: proposal.freelancer,
      amount_cents: proposal.amount_cents,
      status: status,
      started_at: Time.zone.parse(started_at),
      completed_at: completed_at && Time.zone.parse(completed_at)
    )
    job.update!(status: :closed)
    contracts << contract
  end

  review_data.each do |job_key, contract_reviews|
    contract = Contract.find_by!(job: jobs.fetch(job_key))
    contract_reviews.each do |reviewer_key, reviewee_key, rating, body|
      review = Review.find_or_initialize_by(contract: contract, reviewer: users.fetch(reviewer_key))
      review.update!(reviewee: users.fetch(reviewee_key), rating: rating, body: body)
      reviews << review
    end
  end

  {
    ecommerce_migration: %i[ kurnia sarah ],
    rails_8_upgrade: %i[ kurnia diego nina ],
    aws_cleanup: %i[ sarah aisha liam ]
  }.each do |job_key, freelancer_keys|
    job = jobs.fetch(job_key)
    freelancer_keys.each do |freelancer_key|
      shortlist = Shortlist.find_or_initialize_by(job: job, client: job.client, freelancer: users.fetch(freelancer_key))
      shortlist.save!
      shortlists << shortlist
    end
  end
end

puts <<~SUMMARY
  Gigoo demo data created.

  Demo login:
  alice@gigoo.test / password
  kurnia@gigoo.test / password
  sarah@gigoo.test / password

  Created:
  #{users.size} users
  #{client_profiles.size} client profiles
  #{freelancer_profiles.size} freelancer profiles
  #{jobs.size} jobs
  #{proposals.uniq.size} proposals
  #{contracts.uniq.size} contracts
  #{reviews.uniq.size} reviews
  #{shortlists.uniq.size} shortlists
SUMMARY
