class FreelancersController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :resume_session

  def index
    @freelancers = FreelancerProfile.includes(:user).order(created_at: :desc)
    @freelancers = search(@freelancers)
  end

  def show
    @freelancer = FreelancerProfile.includes(:user).find(params[:id])
    return unless Current.user&.client_profile

    @client_jobs = Current.user.posted_jobs.where(status: %i[ draft open ]).order(created_at: :desc)
    @shortlisted_job_ids = Shortlist.where(
      client: Current.user,
      freelancer: @freelancer.user,
      job: @client_jobs
    ).pluck(:job_id)
  end

  private

  def search(scope)
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      scope = scope.where(
        "freelancer_profiles.title ILIKE :query OR freelancer_profiles.bio ILIKE :query OR freelancer_profiles.location ILIKE :query",
        query: query
      )
    end

    scope = scope.where("freelancer_profiles.skills @> ARRAY[?]::varchar[]", params[:skill].strip) if params[:skill].present?
    scope
  end
end
