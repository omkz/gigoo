require "rails_helper"

RSpec.describe FreelancerProfile, type: :model do
  it "allows a non-negative hourly rate" do
    expect(build(:freelancer_profile, hourly_rate_cents: 0)).to be_valid
    expect(build(:freelancer_profile, hourly_rate_cents: nil)).to be_valid
    expect(build(:freelancer_profile, hourly_rate_cents: -1)).not_to be_valid
  end

  it "converts an hourly rate in dollars to cents" do
    profile = build(:freelancer_profile, hourly_rate: "123.45")

    expect(profile.hourly_rate_cents).to eq(12_345)
    expect(profile.hourly_rate).to eq("123.45")
    expect(profile).to be_valid
  end

  it "rejects a malformed hourly rate while still allowing a blank rate" do
    malformed = build(:freelancer_profile, hourly_rate: "many")
    blank = build(:freelancer_profile, hourly_rate: "")

    expect(malformed).not_to be_valid
    expect(malformed.errors[:hourly_rate]).to include("must be a non-negative number")
    expect(blank).to be_valid
    expect(blank.hourly_rate_cents).to be_nil
  end

  it "allows only one profile per user" do
    profile = create(:freelancer_profile)

    expect(build(:freelancer_profile, user: profile.user)).not_to be_valid
  end

  it "exposes only role-scoped completed work and review evidence" do
    profile = create(:freelancer_profile)
    create(:client_profile, user: profile.user)
    repeat_client = create(:client_profile).user
    other_client = create(:client_profile).user

    first_repeat = create(:contract, :completed, job: create(:job, client: repeat_client), client: repeat_client, freelancer: profile.user)
    second_repeat = create(:contract, :completed, job: create(:job, client: repeat_client), client: repeat_client, freelancer: profile.user)
    other_completed = create(:contract, :completed, job: create(:job, client: other_client), client: other_client, freelancer: profile.user)
    create(:contract, job: create(:job, client: other_client), client: other_client, freelancer: profile.user, status: :active)
    create(:contract, job: create(:job, client: other_client), client: other_client, freelancer: profile.user, status: :cancelled)

    create(:review, contract: first_repeat, reviewer: repeat_client, reviewee: profile.user, rating: 5)
    create(:review, contract: second_repeat, reviewer: repeat_client, reviewee: profile.user, rating: 5)
    create(:review, contract: other_completed, reviewer: other_client, reviewee: profile.user, rating: 3)

    client_job = create(:job, client: profile.user)
    client_contract = create(:contract, :completed, job: client_job, client: profile.user)
    create(:review, contract: client_contract, reviewer: client_contract.freelancer, reviewee: profile.user, rating: 2)

    expect(profile.completed_contracts.count).to eq(3)
    expect(profile.repeat_client_count).to eq(1)
    expect(profile.review_count).to eq(3)
    expect(profile.average_rating).to eq(BigDecimal("4.3333333333333333"))
    expect(profile.low_rating_reviews.count).to eq(1)
    expect(profile.received_reviews).not_to include(client_contract.reviews.first)
  end
end
