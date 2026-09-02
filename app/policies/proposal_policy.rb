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

  def edit?
    update?
  end

  def update?
    user.present? &&
      record.freelancer == user &&
      record.draft? &&
      record.job.open?
  end

  def submit?
    user.present? &&
      user.freelancer_profile.present? &&
      record.freelancer == user &&
      record.draft? &&
      record.job.open?
  end
end
