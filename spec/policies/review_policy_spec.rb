require "rails_helper"

RSpec.describe ReviewPolicy do
  it "allows each contract participant to review the other party after completion" do
    contract = create(:contract, :completed)
    client_review = build(:review, contract: contract, reviewer: contract.client, reviewee: contract.freelancer)
    freelancer_review = build(:review, contract: contract, reviewer: contract.freelancer, reviewee: contract.client)

    expect(described_class.new(contract.client, client_review)).to be_create
    expect(described_class.new(contract.freelancer, freelancer_review)).to be_create
  end

  it "rejects active and cancelled contracts" do
    active_review = build(:review, contract: create(:contract, status: :active))
    cancelled_review = build(:review, contract: create(:contract, status: :cancelled))

    expect(described_class.new(active_review.reviewer, active_review)).not_to be_create
    expect(described_class.new(cancelled_review.reviewer, cancelled_review)).not_to be_create
  end

  it "rejects unrelated users and incorrect reviewees" do
    contract = create(:contract, :completed)
    unrelated = create(:user)
    unrelated_review = build(:review, contract: contract, reviewer: unrelated, reviewee: contract.freelancer)
    incorrect_review = build(:review, contract: contract, reviewer: contract.client, reviewee: contract.client)

    expect(described_class.new(unrelated, unrelated_review)).not_to be_create
    expect(described_class.new(contract.client, incorrect_review)).not_to be_create
  end

  it "rejects a second review from the same reviewer" do
    existing = create(:review)
    duplicate = build(:review, contract: existing.contract, reviewer: existing.reviewer, reviewee: existing.reviewee)

    expect(described_class.new(existing.reviewer, duplicate)).not_to be_create
  end
end
