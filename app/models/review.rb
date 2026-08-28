class Review < ApplicationRecord
  belongs_to :contract
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"

  validates :rating, numericality: { only_integer: true, in: 1..5 }
  validates :reviewer_id, uniqueness: { scope: :contract_id }
  validate :reviewer_is_not_reviewee
  validate :contract_is_completed

  private

  def reviewer_is_not_reviewee
    errors.add(:reviewer, "cannot review themselves") if reviewer.present? && reviewer == reviewee
  end

  def contract_is_completed
    errors.add(:contract, "must be completed") if contract.present? && !contract.completed?
  end
end
