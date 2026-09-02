class Workspace
  VALID = %w[ freelancer client ].freeze

  def self.capability?(user, workspace)
    return false unless user && VALID.include?(workspace)

    case workspace
    when "freelancer" then user.freelancer_profile.present?
    when "client" then user.client_profile.present?
    end
  end

  def self.available_for(user)
    return [] unless user

    VALID.select { |workspace| capability?(user, workspace) }
  end

  # Resolves the active workspace for a user: the requested workspace when the
  # user actually has that capability, otherwise a deterministic fallback.
  def self.resolve(user, requested: nil)
    available = available_for(user)
    return nil if available.empty?
    return requested if available.include?(requested)
    return available.first if available.size == 1

    "freelancer"
  end
end
