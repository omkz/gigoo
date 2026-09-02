class FreelancerProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :hourly_rate_cents,
    numericality: { greater_than_or_equal_to: 0, only_integer: true },
    allow_nil: true
  validate :hourly_rate_input_is_valid

  def hourly_rate
    return @hourly_rate_input if defined?(@hourly_rate_input)

    BigDecimal(hourly_rate_cents.to_s) / 100 if hourly_rate_cents.present?
  end

  def hourly_rate=(value)
    @hourly_rate_input = value
    @hourly_rate_input_invalid = false
    self.hourly_rate_cents = if value.present?
      amount = BigDecimal(value.to_s)
      raise ArgumentError unless amount.finite?

      (amount * 100).round.to_i
    end
  rescue ArgumentError
    @hourly_rate_input_invalid = true
    self.hourly_rate_cents = nil
  end

  def self.trust_evidence_for(user_ids)
    user_ids = user_ids.compact.uniq
    completed_contracts = Contract.completed.where(freelancer_id: user_ids)
    role_reviews = Review
      .joins(:contract)
      .where(contracts: { freelancer_id: user_ids })
      .where("reviews.reviewee_id = contracts.freelancer_id")

    completed_counts = completed_contracts.group(:freelancer_id).count
    review_counts = role_reviews.group(:reviewee_id).count
    average_ratings = role_reviews.group(:reviewee_id).average(:rating)
    low_rating_counts = role_reviews.where(rating: ..3).group(:reviewee_id).count
    repeat_pairs = completed_contracts
      .group(:freelancer_id, :client_id)
      .having("COUNT(*) >= 2")
      .count
    repeat_counts = repeat_pairs.keys.group_by(&:first).transform_values(&:count)

    user_ids.index_with do |user_id|
      {
        average_rating: average_ratings[user_id],
        review_count: review_counts.fetch(user_id, 0),
        completed_contract_count: completed_counts.fetch(user_id, 0),
        repeat_client_count: repeat_counts.fetch(user_id, 0),
        low_rating_count: low_rating_counts.fetch(user_id, 0)
      }
    end
  end

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

  private

  def hourly_rate_input_is_valid
    errors.add(:hourly_rate, "must be a non-negative number") if @hourly_rate_input_invalid
  end
end
