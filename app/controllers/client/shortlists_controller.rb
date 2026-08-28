module Client
  class ShortlistsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    before_action :set_job

    def index
      authorize @job, :shortlist?
      @shortlists = @job.shortlists.includes(freelancer: :freelancer_profile).order(created_at: :desc)
      @trust_evidence = FreelancerProfile.trust_evidence_for(@shortlists.map(&:freelancer_id))
    end

    def create
      freelancer_profile = FreelancerProfile.find(params[:freelancer_profile_id])
      @shortlist = @job.shortlists.new(client: Current.user, freelancer: freelancer_profile.user)
      authorize @shortlist

      if @shortlist.save
        redirect_to freelancer_path(freelancer_profile), notice: "Freelancer was added to the shortlist."
      else
        redirect_to freelancer_path(freelancer_profile), alert: @shortlist.errors.full_messages.to_sentence
      end
    end

    def destroy
      @shortlist = @job.shortlists.find(params[:id])
      authorize @shortlist
      @shortlist.destroy!
      redirect_to client_job_shortlists_path(@job), notice: "Freelancer was removed from the shortlist."
    end

    private

    def set_job
      @job = Job.find(params[:job_id])
    end

    def forbid_access
      head :forbidden
    end
  end
end
