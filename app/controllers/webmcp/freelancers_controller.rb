module Webmcp
  class FreelancersController < BaseController
    def index
      freelancers = FreelancerProfile.includes(:user).order(created_at: :desc)
      freelancers = filter(freelancers).limit(result_limit).to_a
      trust_evidence = FreelancerProfile.trust_evidence_for(freelancers.map(&:user_id))

      render json: {
        freelancers: freelancers.map { |profile| freelancer_json(profile, trust_evidence.fetch(profile.user_id)) },
        count: freelancers.size
      }
    end

    def show
      profile = FreelancerProfile.includes(:user).find(params[:id])
      reviews = profile.received_reviews
        .includes(reviewer: :client_profile)
        .order(created_at: :desc)
        .limit(5)
      evidence = FreelancerProfile.trust_evidence_for([ profile.user_id ]).fetch(profile.user_id)

      render json: freelancer_json(profile, evidence).merge(
        recent_reviews: reviews.map { |review| freelancer_review_json(review) }
      )
    end

    private

    def filter(scope)
      if params[:query].present?
        query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query].strip)}%"
        scope = scope.where(
          "freelancer_profiles.title ILIKE :query OR freelancer_profiles.bio ILIKE :query OR freelancer_profiles.location ILIKE :query",
          query: query
        )
      end

      if params[:location].present?
        location = "%#{ActiveRecord::Base.sanitize_sql_like(params[:location].strip)}%"
        scope = scope.where("freelancer_profiles.location ILIKE ?", location)
      end

      scope = scope.where("freelancer_profiles.skills @> ARRAY[?]::varchar[]", params[:skill].strip) if params[:skill].present?

      maximum_rate = usd_cents_parameter(:max_hourly_rate_usd)
      maximum_rate ? scope.where(hourly_rate_cents: ..maximum_rate) : scope
    end

    def freelancer_json(profile, evidence)
      {
        profile_id: profile.id,
        name: profile.user.name,
        title: profile.title,
        bio: profile.bio,
        location: profile.location,
        hourly_rate_usd: usd_amount(profile.hourly_rate_cents),
        currency: "USD",
        skills: profile.skills,
        trust_evidence: trust_evidence_json(evidence),
        url: freelancer_path(profile)
      }
    end

    def trust_evidence_json(evidence)
      evidence.merge(average_rating: numeric_average(evidence[:average_rating]))
    end

    def freelancer_review_json(review)
      {
        rating: review.rating,
        body: review.body,
        reviewer: {
          name: review.reviewer.name,
          company_name: review.reviewer.client_profile&.company_name
        },
        created_at: review.created_at.iso8601
      }
    end
  end
end
