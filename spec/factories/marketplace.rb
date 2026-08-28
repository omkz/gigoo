FactoryBot.define do
  factory :client_profile do
    association :user, factory: :user, role: :client
    company_name { "Acme Inc." }
    bio { "A growing company." }
    location { "Jakarta" }
  end

  factory :freelancer_profile do
    association :user, factory: :user, role: :freelancer
    title { "Rails Developer" }
    bio { "I build reliable web applications." }
    hourly_rate_cents { 25_000 }
    location { "Bandung" }
    skills { [ "Ruby", "Rails" ] }
  end

  factory :job do
    association :client, factory: :user, role: :client
    title { "Build a marketplace feature" }
    description { "Implement and test a marketplace feature." }
    budget_cents { 500_000 }
    skills { [ "Ruby", "Rails" ] }
    status { :open }
  end

  factory :proposal do
    job
    association :freelancer, factory: :user, role: :freelancer
    amount_cents { 450_000 }
    message { "I can deliver this project." }
    status { :pending }
  end

  factory :contract do
    job
    client { job.client }
    association :freelancer, factory: :user, role: :freelancer
    amount_cents { 450_000 }
    status { :active }
    started_at { Time.current }

    trait :completed do
      status { :completed }
      completed_at { Time.current }
    end
  end

  factory :review do
    association :contract, :completed
    reviewer { contract.client }
    reviewee { contract.freelancer }
    rating { 5 }
    body { "Excellent work." }
  end

  factory :shortlist do
    job
    client { job.client }
    association :freelancer, factory: :user, role: :freelancer
  end
end
