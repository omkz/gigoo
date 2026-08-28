class ClientProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  def received_reviews
    Review.for_client_role(user)
  end

  def completed_contracts
    user.client_contracts.completed
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

  def repeat_freelancer_count
    completed_contracts
      .group(:freelancer_id)
      .having("COUNT(*) >= 2")
      .count
      .size
  end
end
