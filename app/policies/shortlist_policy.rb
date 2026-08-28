class ShortlistPolicy < ApplicationPolicy
  def create?
    client_owns_job? &&
      record.freelancer.freelancer_profile.present? &&
      record.freelancer != user
  end

  def destroy?
    client_owns_job? && record.client == user
  end

  private

  def client_owns_job?
    user.present? && user.client_profile.present? && record.job.client == user
  end
end
