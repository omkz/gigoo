class WorkPolicy < ApplicationPolicy
  def show?
    user.present? && user.freelancer_profile.present?
  end
end
