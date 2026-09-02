module WorkspaceContext
  extend ActiveSupport::Concern

  included do
    helper_method :current_workspace, :available_workspaces, :dual_capability_workspace?
  end

  class_methods do
    # Declares that entering this controller establishes a given workspace as
    # active, e.g. `sets_active_workspace :client` in a Client:: controller.
    def sets_active_workspace(workspace)
      before_action { set_active_workspace(workspace) }
    end
  end

  private

  def current_workspace
    return @current_workspace if defined?(@current_workspace)

    @current_workspace = Workspace.resolve(Current.user, requested: session[:workspace])
    session[:workspace] = @current_workspace
    @current_workspace
  end

  def available_workspaces
    Workspace.available_for(Current.user)
  end

  def dual_capability_workspace?
    available_workspaces.size > 1
  end

  def set_active_workspace(workspace)
    workspace = workspace.to_s
    return unless Workspace.capability?(Current.user, workspace)

    session[:workspace] = workspace
    @current_workspace = workspace
  end
end
