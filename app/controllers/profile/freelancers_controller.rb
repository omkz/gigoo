module Profile
  class FreelancersController < ApplicationController
    before_action :set_freelancer_profile

    def edit
      authorize @freelancer_profile
    end

    def update
      authorize @freelancer_profile

      if @freelancer_profile.update(freelancer_profile_params)
        redirect_to profile_path, notice: "Freelancer profile was updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_freelancer_profile
      @freelancer_profile = Current.user.freelancer_profile
      raise ActiveRecord::RecordNotFound unless @freelancer_profile
    end

    def freelancer_profile_params
      permitted = params.require(:freelancer_profile).permit(:title, :location, :hourly_rate, :skills, :bio)

      permitted.slice(:title, :location, :hourly_rate, :bio).merge(
        skills: permitted[:skills].to_s.split(",").map(&:strip).reject(&:blank?).uniq
      )
    end
  end
end
