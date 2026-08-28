module Webmcp
  class ClientsController < BaseController
    def show
      profile = ClientProfile.includes(:user).find(params[:id])
      reviews = profile.received_reviews
        .includes(reviewer: :freelancer_profile)
        .order(created_at: :desc)
        .limit(5)

      render json: {
        profile_id: profile.id,
        name: profile.user.name,
        company_name: profile.company_name,
        bio: profile.bio,
        location: profile.location,
        payment_verified: profile.payment_verified,
        trust_evidence: {
          average_rating: numeric_average(profile.average_rating),
          review_count: profile.review_count,
          completed_contract_count: profile.completed_contracts.count,
          repeat_freelancer_count: profile.repeat_freelancer_count,
          low_rating_count: profile.low_rating_reviews.count
        },
        recent_reviews: reviews.map { |review| client_review_json(review) },
        url: client_path(profile)
      }
    end

    private

    def client_review_json(review)
      {
        rating: review.rating,
        body: review.body,
        reviewer: {
          name: review.reviewer.name,
          title: review.reviewer.freelancer_profile&.title
        },
        created_at: review.created_at.iso8601
      }
    end
  end
end
