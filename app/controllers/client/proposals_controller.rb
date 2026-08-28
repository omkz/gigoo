module Client
  class ProposalsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    def index
      @job = Job.includes(:contract).find(params[:job_id])
      authorize @job, :proposals?
      @proposals = @job.proposals.includes(freelancer: :freelancer_profile).order(created_at: :desc)
    end

    def accept
      @job = Job.find(params[:job_id])
      @proposal = @job.proposals.find(params[:id])
      authorize @proposal, :accept?

      ApplicationRecord.transaction do
        @job.lock!
        @proposal.reload
        authorize @proposal, :accept?

        @proposal.update!(status: :accepted)
        @contract = Contract.create!(
          job: @job,
          client: @job.client,
          freelancer: @proposal.freelancer,
          amount_cents: @proposal.amount_cents,
          status: :active,
          started_at: Time.current
        )
        @job.proposals.pending.where.not(id: @proposal.id).update_all(
          status: Proposal.statuses[:rejected],
          updated_at: Time.current
        )
        @job.update!(status: :closed)
      end

      redirect_to client_contract_path(@contract), notice: "Proposal accepted and contract created."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      redirect_to client_job_proposals_path(@job), alert: "Proposal could not be accepted. Please try again."
    end

    private

    def forbid_access
      head :forbidden
    end
  end
end
