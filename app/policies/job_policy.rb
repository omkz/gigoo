class JobPolicy < ApplicationPolicy
  def index?
    client?
  end

  def create?
    client?
  end

  def update?
    client? && record.client == user
  end

  def publish?
    update?
  end

  def close?
    update?
  end

  def proposals?
    update?
  end

  def shortlist?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.client_profile.present?

      scope.where(client: user)
    end
  end

  private

  def client?
    user.client_profile.present?
  end
end
