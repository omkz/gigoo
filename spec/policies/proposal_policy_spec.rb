require "rails_helper"

RSpec.describe ProposalPolicy do
  it "allows a freelancer-profile user to propose to another client's open job" do
    proposal = build(:proposal)

    expect(described_class.new(proposal.freelancer, proposal)).to be_create
  end

  it "rejects users without a freelancer profile" do
    proposal = build(:proposal, freelancer: build(:user))

    expect(described_class.new(proposal.freelancer, proposal)).not_to be_create
  end

  it "rejects the job owner even when they have a freelancer profile" do
    job = create(:job, status: :open)
    create(:freelancer_profile, user: job.client)
    proposal = build(:proposal, job: job, freelancer: job.client)

    expect(described_class.new(job.client, proposal)).not_to be_create
  end

  it "rejects proposals to non-open jobs" do
    proposal = build(:proposal, job: build(:job, status: :draft))

    expect(described_class.new(proposal.freelancer, proposal)).not_to be_create
  end

  describe "accepting a proposal" do
    it "allows the owning client to accept a pending proposal for an open job" do
      proposal = create(:proposal)

      expect(described_class.new(proposal.job.client, proposal)).to be_accept
    end

    it "requires client capability and ownership" do
      proposal = create(:proposal)
      other_client = create(:client_profile).user

      expect(described_class.new(create(:user), proposal)).not_to be_accept
      expect(described_class.new(other_client, proposal)).not_to be_accept
    end

    it "rejects non-pending proposals, non-open jobs, and jobs with contracts" do
      non_pending = create(:proposal, status: :rejected)
      non_open = create(:proposal)
      non_open.job.update!(status: :closed)
      contracted = create(:proposal)
      create(:contract, job: contracted.job)

      expect(described_class.new(non_pending.job.client, non_pending)).not_to be_accept
      expect(described_class.new(non_open.job.client, non_open)).not_to be_accept
      expect(described_class.new(contracted.job.client, contracted)).not_to be_accept
    end
  end

  describe "editing a draft" do
    it "allows only the owning freelancer to edit an open-job draft" do
      proposal = create(:proposal, status: :draft)

      expect(described_class.new(proposal.freelancer, proposal)).to be_edit
      expect(described_class.new(proposal.freelancer, proposal)).to be_update
      expect(described_class.new(create(:freelancer_profile).user, proposal)).not_to be_update
    end

    it "rejects submitted proposals and drafts whose jobs are no longer open" do
      submitted = create(:proposal, status: :pending)
      closed_draft = create(:proposal, status: :draft)
      closed_draft.job.update!(status: :closed)

      expect(described_class.new(submitted.freelancer, submitted)).not_to be_update
      expect(described_class.new(closed_draft.freelancer, closed_draft)).not_to be_update
    end
  end
end
