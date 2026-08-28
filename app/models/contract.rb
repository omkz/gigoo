class Contract < ApplicationRecord
  belongs_to :job
  belongs_to :client, class_name: "User"
  belongs_to :freelancer, class_name: "User"

  has_many :reviews, dependent: :destroy

  enum :status, { active: 0, completed: 1, cancelled: 2 }

  validates :amount_cents,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
