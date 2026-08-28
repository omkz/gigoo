class ReviewPolicy < ApplicationPolicy
  def create?
    return false unless user.present? && record.contract&.completed?
    return false unless record.reviewer == user

    other_party = if user == record.contract.client
      record.contract.freelancer
    elsif user == record.contract.freelancer
      record.contract.client
    end

    other_party.present? &&
      record.reviewee == other_party &&
      !record.contract.reviews.exists?(reviewer: user)
  end
end
