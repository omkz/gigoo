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
end
