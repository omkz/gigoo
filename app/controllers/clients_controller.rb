class ClientsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @client = ClientProfile.includes(:user).find(params[:id])
    @review_count = @client.review_count
    @average_rating = @client.average_rating
    @completed_contract_count = @client.completed_contracts.count
    @repeat_freelancer_count = @client.repeat_freelancer_count
    @low_rating_count = @client.low_rating_reviews.count
    @reviews = @client.received_reviews.includes(reviewer: %i[ client_profile freelancer_profile ]).order(created_at: :desc).limit(5)
  end
end
