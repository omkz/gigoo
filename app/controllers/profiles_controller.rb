class ProfilesController < ApplicationController
  def show
    @freelancer_profile = Current.user.freelancer_profile
    @client_profile = Current.user.client_profile
  end
end
