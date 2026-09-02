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

      render json: shortlist_json(shortlist, freelancer_profile, created).merge(
        turbo_stream: turbo_stream_updates(job, freelancer_profile, shortlisted: true)
      ), status: created ? :created : :ok
    end

    def destroy
      job = Job.find(id_parameter(:job_id))
      freelancer_profile = FreelancerProfile.includes(:user).find(id_parameter(:freelancer_id))
      shortlist = job.shortlists.find_by(client: Current.user, freelancer: freelancer_profile.user)
      authorize shortlist || job.shortlists.new(client: Current.user, freelancer: freelancer_profile.user), :destroy?

      removed = shortlist.present?
      shortlist&.destroy!

      render json: removal_json(job, freelancer_profile, removed).merge(
        turbo_stream: turbo_stream_updates(job, freelancer_profile, shortlisted: false)
      )
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

    def removal_json(job, freelancer_profile, removed)
      {
        result: removed ? "removed" : "already_removed",
        message: removed ? "Freelancer removed from the shortlist." : "Freelancer was already absent from this shortlist.",
        job: {
          id: job.id,
          title: job.title,
          status: job.status,
          shortlist_url: client_job_shortlists_path(job)
        },
        freelancer: {
          profile_id: freelancer_profile.id,
          name: freelancer_profile.user.name,
          title: freelancer_profile.title,
          url: freelancer_path(freelancer_profile)
        },
        shortlist_count: job.shortlists.count
      }
    end

    def turbo_stream_updates(job, freelancer_profile, shortlisted:)
      shortlists = job.shortlists.includes(freelancer: :freelancer_profile).order(created_at: :desc)
      trust_evidence = FreelancerProfile.trust_evidence_for(shortlists.map(&:freelancer_id))

      [
        turbo_stream.replace(
          "shortlist_action_job_#{job.id}_freelancer_#{freelancer_profile.id}",
          partial: "freelancers/shortlist_action",
          locals: { job: job, freelancer_profile: freelancer_profile, shortlisted: shortlisted }
        ),
        turbo_stream.replace(
          "job_#{job.id}_shortlist_link",
          partial: "client/jobs/shortlist_link",
          locals: { job: job, shortlist_count: job.shortlists.count }
        ),
        turbo_stream.replace(
          "job_#{job.id}_shortlist_contents",
          partial: "client/shortlists/contents",
          locals: { job: job, shortlists: shortlists, trust_evidence: trust_evidence }
        )
      ].join
    end
  end
end
