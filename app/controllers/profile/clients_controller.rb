module Profile
  class ClientsController < ApplicationController
    before_action :set_client_profile

    def edit
      authorize @client_profile
    end

    def update
      authorize @client_profile

      if @client_profile.update(client_profile_params)
        redirect_to profile_path, notice: "Client profile was updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_client_profile
      @client_profile = Current.user.client_profile
      raise ActiveRecord::RecordNotFound unless @client_profile
    end

    def client_profile_params
      params.require(:client_profile).permit(:company_name, :location, :bio)
    end
  end
end
