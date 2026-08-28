class User < ApplicationRecord
  enum :role, {
    freelancer: 0,
    client: 1,
    support: 2,
    admin: 3
  }

  has_one :client_profile, dependent: :destroy
  has_one :freelancer_profile, dependent: :destroy
end
