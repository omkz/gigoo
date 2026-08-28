module Client
  class ProposalsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    def index
      @job = Job.find(params[:job_id])
      authorize @job, :proposals?
      @proposals = @job.proposals.includes(freelancer: :freelancer_profile).order(created_at: :desc)
    end

    private

    def forbid_access
      head :forbidden
    end
  end
end
