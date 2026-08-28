module Webmcp
  class JobsController < BaseController
    def index
      jobs = Job.open.includes(client: :client_profile).order(created_at: :desc)
      jobs = filter(jobs).limit(result_limit)

      render json: { jobs: jobs.map { |job| job_json(job) }, count: jobs.size }
    end

    def show
      job = Job.open.includes(client: :client_profile).find(params[:id])

      render json: job_json(job)
    end

    private

    def filter(scope)
      if params[:query].present?
        query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query].strip)}%"
        scope = scope.where("jobs.title ILIKE :query OR jobs.description ILIKE :query", query: query)
      end

      scope = scope.where("jobs.skills @> ARRAY[?]::varchar[]", params[:skill].strip) if params[:skill].present?

      maximum_budget = usd_cents_parameter(:max_budget_usd)
      maximum_budget ? scope.where(budget_cents: ..maximum_budget) : scope
    end

    def job_json(job)
      profile = job.client.client_profile

      {
        id: job.id,
        title: job.title,
        description: job.description,
        budget_usd: usd_amount(job.budget_cents),
        currency: "USD",
        skills: job.skills,
        status: job.status,
        client: {
          profile_id: profile.id,
          name: job.client.name,
          company_name: profile.company_name,
          location: profile.location,
          payment_verified: profile.payment_verified
        },
        url: job_path(job)
      }
    end
  end
end
