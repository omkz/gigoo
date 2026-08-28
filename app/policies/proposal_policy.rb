class ProposalPolicy < ApplicationPolicy
  def create?
    user.present? &&
      user.freelancer_profile.present? &&
      record.job.open? &&
      record.job.client != user
  end

  def accept?
    user.present? &&
      user.client_profile.present? &&
      record.job.client == user &&
      record.job.open? &&
      record.pending? &&
      record.job.contract.blank?
  end
end
