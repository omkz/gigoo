class ClientsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @client = ClientProfile.includes(:user).find(params[:id])
    received_reviews = @client.user.reviews_received
    @review_count = received_reviews.count
    @average_rating = received_reviews.average(:rating)
    @reviews = received_reviews.includes(reviewer: %i[ client_profile freelancer_profile ]).order(created_at: :desc).limit(5)
  end
end
