class ContractPolicy < ApplicationPolicy
  def show_client?
    user.present? && user.client_profile.present? && record.client == user
  end

  def show_freelancer?
    user.present? && record.freelancer == user
  end

  def complete?
    show_client? && record.active?
  end
end
