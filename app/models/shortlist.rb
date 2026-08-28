class Shortlist < ApplicationRecord
  belongs_to :job
  belongs_to :client, class_name: "User"
  belongs_to :freelancer, class_name: "User"

  validates :freelancer_id, uniqueness: { scope: [ :job_id, :client_id ] }
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
    errors.add(:freelancer, "cannot be the client") if client.present? && client == freelancer
  end
end
