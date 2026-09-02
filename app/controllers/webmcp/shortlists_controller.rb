module Webmcp
  class ShortlistsController < BaseController
    before_action :require_webmcp_authentication

    def create
      job = Job.open.find(id_parameter(:job_id))
      freelancer_profile = FreelancerProfile.includes(:user).find(id_parameter(:freelancer_id))
      candidate = job.shortlists.new(client: Current.user, freelancer: freelancer_profile.user)
      authorize candidate

      shortlist, created = find_or_create_shortlist(job, freelancer_profile.user)

      unless shortlist.persisted?
        return render json: { error: shortlist.errors.full_messages.to_sentence }, status: :unprocessable_content
      end

      render json: shortlist_json(shortlist, freelancer_profile, created), status: created ? :created : :ok
    end

    private

    def find_or_create_shortlist(job, freelancer)
      shortlist = job.shortlists.find_or_initialize_by(client: Current.user, freelancer: freelancer)
      return [ shortlist, false ] if shortlist.persisted?

      created = Shortlist.transaction(requires_new: true) { shortlist.save }
      [ shortlist, created ]
    rescue ActiveRecord::RecordNotUnique
      [ job.shortlists.find_by!(client: Current.user, freelancer: freelancer), false ]
    end

    def shortlist_json(shortlist, freelancer_profile, created)
      {
        result: created ? "created" : "already_shortlisted",
        message: created ? "Freelancer added to the shortlist." : "Freelancer was already on this shortlist.",
        shortlist: {
          id: shortlist.id,
          created_at: shortlist.created_at.iso8601,
          job: {
            id: shortlist.job_id,
            title: shortlist.job.title,
            status: shortlist.job.status,
            shortlist_url: client_job_shortlists_path(shortlist.job)
          },
          freelancer: {
            profile_id: freelancer_profile.id,
            name: freelancer_profile.user.name,
            title: freelancer_profile.title,
            url: freelancer_path(freelancer_profile)
          }
        }
      }
    end
  end
end
