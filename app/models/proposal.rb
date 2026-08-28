class Proposal < ApplicationRecord
  belongs_to :job
  belongs_to :freelancer, class_name: "User"

  enum :status, { pending: 0, accepted: 1, rejected: 2, withdrawn: 3 }

  validates :amount_cents,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :message, presence: true
  validates :freelancer_id, uniqueness: { scope: :job_id }
  validate :freelancer_has_freelancer_profile
  validate :freelancer_is_not_job_client

  private

  def freelancer_has_freelancer_profile
    errors.add(:freelancer, "must have a freelancer profile") if freelancer.present? && freelancer.freelancer_profile.blank?
  end

  def freelancer_is_not_job_client
    errors.add(:freelancer, "cannot propose to their own job") if job.present? && freelancer.present? && freelancer == job.client
  end
end
