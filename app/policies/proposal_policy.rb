class ProposalPolicy < ApplicationPolicy
  def create?
    user.present? &&
      user.freelancer_profile.present? &&
      record.job.open? &&
      record.job.client != user
  end
end
