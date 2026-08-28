class ContractPolicy < ApplicationPolicy
  def show?
    user.present? && user.client_profile.present? && record.client == user
  end
end
