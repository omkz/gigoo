module Client
  class ContractsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    def show
      @contract = Contract.includes(:job, freelancer: :freelancer_profile).find(params[:id])
      authorize @contract
    end

    private

    def forbid_access
      head :forbidden
    end
  end
end
