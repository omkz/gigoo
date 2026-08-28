class FreelancerProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :hourly_rate_cents,
    numericality: { greater_than_or_equal_to: 0, only_integer: true },
    allow_nil: true

  def received_reviews
    Review.for_freelancer_role(user)
  end

  def completed_contracts
    user.freelancer_contracts.completed
  end

  def average_rating
    received_reviews.average(:rating)
  end

  def review_count
    received_reviews.count
  end

  def low_rating_reviews
    received_reviews.where(rating: ..3)
  end

  def repeat_client_count
    completed_contracts
      .group(:client_id)
      .having("COUNT(*) >= 2")
      .count
      .size
  end
end
