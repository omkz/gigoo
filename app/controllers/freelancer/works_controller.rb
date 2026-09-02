module Freelancer
  class WorksController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    def show
      authorize :work, :show?

      @active_contracts = Current.user.freelancer_contracts
        .active
        .includes(:job, client: :client_profile)
        .order(created_at: :desc)
      @proposals = Current.user.proposals
        .includes(job: [ :contract, { client: :client_profile } ])
        .order(created_at: :desc)
      @completed_contracts = Current.user.freelancer_contracts
        .completed
        .includes(:job, client: :client_profile)
        .order(completed_at: :desc, created_at: :desc)
    end

    private

    def forbid_access
      head :forbidden
    end
  end
end
