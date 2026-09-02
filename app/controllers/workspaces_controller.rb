class WorkspacesController < ApplicationController
  def update
    requested = params[:workspace].to_s
    session[:workspace] = requested if Workspace.capability?(Current.user, requested)

    redirect_to current_workspace == "client" ? client_jobs_path : jobs_path
  end
end
