module Client
  class JobsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    before_action :set_job, only: %i[ edit update publish close ]

    def index
      authorize Job
      @jobs = policy_scope(Job).order(created_at: :desc)
      @proposal_counts = Proposal.where(job: @jobs).where.not(status: :draft).group(:job_id).count
      @shortlist_counts = Shortlist.where(job: @jobs).group(:job_id).count
    end

    def new
      @job = Current.user.posted_jobs.new
      authorize @job
    end

    def create
      @job = Current.user.posted_jobs.new(job_attributes)
      authorize @job

      if @job.save
        redirect_to client_jobs_path, notice: "Job was created as a draft."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @job
    end

    def update
      authorize @job

      if @job.update(job_attributes)
        redirect_to client_jobs_path, notice: "Job was updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def publish
      authorize @job

      if @job.draft? && @job.update(status: :open)
        redirect_to client_jobs_path, notice: "Job was published."
      else
        redirect_to client_jobs_path, alert: "Only draft jobs can be published."
      end
    end

    def close
      authorize @job

      if @job.open? && @job.update(status: :closed)
        redirect_to client_jobs_path, notice: "Job was closed."
      else
        redirect_to client_jobs_path, alert: "Only open jobs can be closed."
      end
    end

    private

    def set_job
      @job = Job.find(params[:id])
    end

    def job_attributes
      permitted = params.require(:job).permit(:title, :description, :budget, :skills)

      permitted.slice(:title, :description, :budget).merge(
        skills: permitted[:skills].to_s.split(",").map(&:strip).reject(&:blank?).uniq
      )
    end

    def forbid_access
      head :forbidden
    end
  end
end
