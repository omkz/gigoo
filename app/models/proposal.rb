class Proposal < ApplicationRecord
  belongs_to :job
  belongs_to :freelancer, class_name: "User"

  enum :status, { pending: 0, accepted: 1, rejected: 2, withdrawn: 3 }

  validates :amount_cents,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :message, presence: true
  validates :freelancer_id, uniqueness: { scope: :job_id }
end
