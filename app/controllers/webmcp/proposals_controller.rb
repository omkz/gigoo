module Webmcp
  class ProposalsController < BaseController
    before_action :require_webmcp_authentication

    def create
      job = Job.open.find(id_parameter(:job_id))
      proposal = job.proposals.new(
        freelancer: Current.user,
        message: params[:cover_letter],
        amount_cents: usd_cents_parameter(:proposed_amount_usd),
        status: :draft
      )
      authorize proposal

      existing_proposal = job.proposals.find_by(freelancer: Current.user)
      return render_existing(existing_proposal) if existing_proposal

      if proposal.save
        render json: proposal_json(proposal, "created", "Proposal draft created. It has not been submitted.").merge(
          turbo_stream: proposal_turbo_stream(proposal)
        ), status: :created
      else
        render json: { error: proposal.errors.full_messages.to_sentence }, status: :unprocessable_content
      end
    end

    private

    def render_existing(proposal)
      result = proposal.draft? ? "draft_already_exists" : "proposal_already_exists"
      message = if proposal.draft?
        "A proposal draft already exists for this job. No duplicate was created."
      else
        "A #{proposal.status} proposal already exists for this job. No draft was created."
      end

      render json: proposal_json(proposal, result, message).merge(
        turbo_stream: proposal.draft? ? proposal_turbo_stream(proposal) : nil
      )
    end

    def proposal_json(proposal, result, message)
      {
        result: result,
        message: message,
        proposal: {
          id: proposal.id,
          status: proposal.status
        },
        job: {
          id: proposal.job_id,
          title: proposal.job.title,
          status: proposal.job.status,
          url: job_path(proposal.job)
        },
        proposed_amount_usd: usd_amount(proposal.amount_cents),
        currency: "USD",
        review_url: proposal.draft? ? edit_freelancer_proposal_path(proposal) : job_path(proposal.job)
      }
    end

    def proposal_turbo_stream(proposal)
      turbo_stream.replace(
        "job_#{proposal.job_id}_proposal_action",
        partial: "jobs/proposal_action",
        locals: { job: proposal.job, existing_proposal: proposal, proposal: nil }
      )
    end
  end
end
