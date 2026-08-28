class Proposal < ApplicationRecord
  belongs_to :job
  belongs_to :freelancer, class_name: "User"

  enum :status, { pending: 0, accepted: 1, rejected: 2, withdrawn: 3 }

  validates :amount_cents,
    presence: true,
    numericality: { greater_than: 0, only_integer: true }
  validates :message, presence: true
  validates :freelancer_id, uniqueness: { scope: :job_id }
  validate :freelancer_has_freelancer_profile
  validate :job_is_open
  validate :freelancer_is_not_job_client

  def amount
    BigDecimal(amount_cents.to_s) / 100 if amount_cents.present?
  end

  def amount=(value)
    self.amount_cents = value.present? ? (BigDecimal(value.to_s) * 100).round.to_i : nil
  rescue ArgumentError
    self.amount_cents = nil
  end

  private

  def freelancer_has_freelancer_profile
    errors.add(:freelancer, "must have a freelancer profile") if freelancer.present? && freelancer.freelancer_profile.blank?
  end

  def job_is_open
    errors.add(:job, "must be open") if job.present? && !job.open?
  end

  def freelancer_is_not_job_client
    errors.add(:freelancer, "cannot propose to their own job") if job.present? && freelancer.present? && freelancer == job.client
  end
end
