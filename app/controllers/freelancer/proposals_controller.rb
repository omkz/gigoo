module Freelancer
  class ProposalsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    before_action :set_proposal

    def edit
      authorize @proposal
    end

    def update
      authorize @proposal

      if @proposal.update(proposal_params)
        redirect_to edit_freelancer_proposal_path(@proposal), notice: "Proposal draft was updated. It has not been submitted."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_proposal
      @proposal = Proposal.find(params[:id])
    end

    def proposal_params
      params.require(:proposal).permit(:amount, :message)
    end

    def forbid_access
      head :forbidden
    end
  end
end
