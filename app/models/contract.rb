class Contract < ApplicationRecord
  belongs_to :job
  belongs_to :client, class_name: "User"
  belongs_to :freelancer, class_name: "User"

  has_many :reviews, dependent: :destroy

  enum :status, { active: 0, completed: 1, cancelled: 2 }

  validates :amount_cents,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :job_id, uniqueness: true
  validate :client_owns_job
  validate :freelancer_has_freelancer_profile
  validate :client_is_not_freelancer

  private

  def client_owns_job
    errors.add(:client, "must own the job") if job.present? && client.present? && client != job.client
  end

  def freelancer_has_freelancer_profile
    errors.add(:freelancer, "must have a freelancer profile") if freelancer.present? && freelancer.freelancer_profile.blank?
  end

  def client_is_not_freelancer
    errors.add(:freelancer, "must be different from client") if client.present? && client == freelancer
  end
end
