class JobsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :resume_session

  def index
    @jobs = Job.open.includes(client: :client_profile).order(created_at: :desc)
  end

  def show
    @job = Job.open.includes(client: :client_profile).find(params[:id])
    return unless Current.user

    @existing_proposal = @job.proposals.find_by(freelancer: Current.user)
    @proposal = @job.proposals.new unless @existing_proposal
  end
end
