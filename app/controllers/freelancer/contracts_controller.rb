module Freelancer
  class ContractsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    def show
      @contract = Contract.includes(:job, client: :client_profile).find(params[:id])
      authorize @contract, :show_freelancer?
      @review = review_for(@contract.client) if @contract.completed?
    end

    private

    def review_for(reviewee)
      @contract.reviews.find_or_initialize_by(reviewer: Current.user) do |review|
        review.reviewee = reviewee
      end
    end

    def forbid_access
      head :forbidden
    end
  end
end
