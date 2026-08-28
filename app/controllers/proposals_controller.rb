class ProposalsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :forbid_access

  def create
    @job = Job.open.includes(client: :client_profile).find(params[:job_id])
    @proposal = @job.proposals.new(proposal_params)
    @proposal.freelancer = Current.user
    authorize @proposal

    if @proposal.save
      redirect_to job_path(@job), notice: "Proposal was submitted."
    else
      render "jobs/show", status: :unprocessable_content
    end
  end

  private

  def proposal_params
    params.require(:proposal).permit(:amount, :message)
  end

  def forbid_access
    head :forbidden
  end
end
