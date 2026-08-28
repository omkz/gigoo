module Client
  class ShortlistsController < ApplicationController
    rescue_from Pundit::NotAuthorizedError, with: :forbid_access

    before_action :set_job

    def index
      authorize @job, :shortlist?
      @shortlists = @job.shortlists.includes(freelancer: :freelancer_profile).order(created_at: :desc)
      @trust_evidence = trust_evidence_for(@shortlists.map(&:freelancer_id))
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

    def trust_evidence_for(freelancer_ids)
      completed_contracts = Contract.completed.where(freelancer_id: freelancer_ids)
      role_reviews = Review
        .joins(:contract)
        .where(contracts: { freelancer_id: freelancer_ids })
        .where("reviews.reviewee_id = contracts.freelancer_id")

      completed_counts = completed_contracts.group(:freelancer_id).count
      review_counts = role_reviews.group(:reviewee_id).count
      average_ratings = role_reviews.group(:reviewee_id).average(:rating)
      low_rating_counts = role_reviews.where(rating: ..3).group(:reviewee_id).count
      repeat_pairs = completed_contracts
        .group(:freelancer_id, :client_id)
        .having("COUNT(*) >= 2")
        .count
      repeat_counts = repeat_pairs.keys.group_by(&:first).transform_values(&:count)

      freelancer_ids.index_with do |freelancer_id|
        {
          average_rating: average_ratings[freelancer_id],
          review_count: review_counts.fetch(freelancer_id, 0),
          completed_contract_count: completed_counts.fetch(freelancer_id, 0),
          repeat_client_count: repeat_counts.fetch(freelancer_id, 0),
          low_rating_count: low_rating_counts.fetch(freelancer_id, 0)
        }
      end
    end

    def set_job
      @job = Job.find(params[:job_id])
    end

    def forbid_access
      head :forbidden
    end
  end
end
