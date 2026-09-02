require "rails_helper"

RSpec.describe Proposal, type: :model do
  it "defines the expected statuses" do
    expect(described_class.statuses).to eq(
      "pending" => 0,
      "accepted" => 1,
      "rejected" => 2,
      "withdrawn" => 3,
      "draft" => 4
    )
  end

  it "supports an unsent draft without changing the default submitted status" do
    expect(build(:proposal, status: :draft)).to be_draft
    expect(build(:proposal)).to be_pending
  end

  it "allows only one proposal from a freelancer per job" do
    proposal = create(:proposal)
    duplicate = build(:proposal, job: proposal.job, freelancer: proposal.freelancer)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:freelancer_id]).to be_present
  end

  it "enforces proposal uniqueness in the database" do
    proposal = create(:proposal)
    duplicate = build(:proposal, job: proposal.job, freelancer: proposal.freelancer)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "requires the freelancer to have a freelancer profile" do
    proposal = build(:proposal, freelancer: build(:user))

    expect(proposal).not_to be_valid
    expect(proposal.errors[:freelancer]).to include("must have a freelancer profile")
  end

  it "converts a normal amount to cents" do
    proposal = build(:proposal, amount: "1234.56")

    expect(proposal.amount_cents).to eq(123_456)
    expect(proposal.amount).to eq(BigDecimal("1234.56"))
  end

  it "requires a positive amount" do
    expect(build(:proposal, amount: "0")).not_to be_valid
    expect(build(:proposal, amount: "-1")).not_to be_valid
  end

  it "requires the job to be open" do
    proposal = build(:proposal, job: build(:job, status: :draft))

    expect(proposal).not_to be_valid
    expect(proposal.errors[:job]).to include("must be open")
  end

  it "does not allow a freelancer to propose to their own job" do
    job = create(:job)
    create(:freelancer_profile, user: job.client)
    proposal = build(:proposal, job: job, freelancer: job.client)

    expect(proposal).not_to be_valid
    expect(proposal.errors[:freelancer]).to include("cannot propose to their own job")
  end
end
