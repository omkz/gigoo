class FreelancerProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :hourly_rate_cents,
    numericality: { greater_than_or_equal_to: 0, only_integer: true },
    allow_nil: true
end
