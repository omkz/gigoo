require "rails_helper"

RSpec.describe Proposal, type: :model do
  it "defines the expected statuses" do
    expect(described_class.statuses).to eq(
      "pending" => 0,
      "accepted" => 1,
      "rejected" => 2,
      "withdrawn" => 3
    )
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
end
