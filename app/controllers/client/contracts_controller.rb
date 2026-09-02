module Client
  class ContractsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    sets_active_workspace :client

    def show
      @contract = Contract.includes(:job, freelancer: :freelancer_profile).find(params[:id])
      authorize @contract, :show_client?
      @review = review_for(@contract.freelancer) if @contract.completed?
    end

    def complete
      @contract = Contract.find(params[:id])
      authorize @contract, :complete?
      @contract.update!(status: :completed, completed_at: Time.current)

      redirect_to client_contract_path(@contract), notice: "Contract was marked complete."
    rescue ActiveRecord::RecordInvalid
      redirect_to client_contract_path(@contract), alert: "Contract could not be completed."
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
