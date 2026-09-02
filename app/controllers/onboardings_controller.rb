class OnboardingsController < ApplicationController
  def show
  end

  def update
    case params[:capability]
    when "find_work"
      add_freelancer_capability
      session[:workspace] = "freelancer"
      redirect_to jobs_path, notice: "Your freelancer presence is ready."
    when "hire_talent"
      add_client_capability
      session[:workspace] = "client"
      redirect_to client_jobs_path, notice: "Your client presence is ready."
    when "both"
      ApplicationRecord.transaction do
        add_freelancer_capability
        add_client_capability
      end
      session[:workspace] = "freelancer"
      redirect_to jobs_path, notice: "Your freelancer and client capabilities are ready."
    else
      @error = "Choose how you want to use Gigoo."
      render :show, status: :unprocessable_content
    end
  end

  private

  def add_freelancer_capability
    Current.user.create_freelancer_profile! unless Current.user.freelancer_profile
  end

  def add_client_capability
    Current.user.create_client_profile! unless Current.user.client_profile
  end
end
