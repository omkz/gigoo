class ReviewsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :forbid_access

  def create
    @contract = Contract.find(params[:contract_id])
    @review = @contract.reviews.new(
      review_params.merge(reviewer: Current.user, reviewee: reviewee)
    )
    authorize @review

    if @review.save
      redirect_to contract_destination, notice: "Review submitted."
    else
      redirect_to contract_destination, alert: @review.errors.full_messages.to_sentence
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :body)
  end

  def reviewee
    return @contract.freelancer if Current.user == @contract.client
    return @contract.client if Current.user == @contract.freelancer
  end

  def contract_destination
    if Current.user == @contract.client
      client_contract_path(@contract)
    else
      freelancer_contract_path(@contract)
    end
  end

  def forbid_access
    head :forbidden
  end
end
