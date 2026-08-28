FactoryBot.define do
  factory :user do
    sequence(:email_address) { |number| "user#{number}@example.com" }
    password_digest { BCrypt::Password.create("password") }
    role { :member }
  end
end
