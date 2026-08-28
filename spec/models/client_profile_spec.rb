require "rails_helper"

RSpec.describe ClientProfile, type: :model do
  it "belongs to a user" do
    expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
  end

  it "allows only one profile per user" do
    profile = create(:client_profile)

    expect(build(:client_profile, user: profile.user)).not_to be_valid
  end

  it "exposes only role-scoped completed work and review evidence" do
    profile = create(:client_profile)
    create(:freelancer_profile, user: profile.user)
    repeat_freelancer = create(:freelancer_profile).user
    other_freelancer = create(:freelancer_profile).user

    first_repeat = create(:contract, :completed, job: create(:job, client: profile.user), client: profile.user, freelancer: repeat_freelancer)
    second_repeat = create(:contract, :completed, job: create(:job, client: profile.user), client: profile.user, freelancer: repeat_freelancer)
    other_completed = create(:contract, :completed, job: create(:job, client: profile.user), client: profile.user, freelancer: other_freelancer)
    create(:contract, job: create(:job, client: profile.user), client: profile.user, freelancer: other_freelancer, status: :active)
    create(:contract, job: create(:job, client: profile.user), client: profile.user, freelancer: other_freelancer, status: :cancelled)

    create(:review, contract: first_repeat, reviewer: repeat_freelancer, reviewee: profile.user, rating: 5)
    create(:review, contract: second_repeat, reviewer: repeat_freelancer, reviewee: profile.user, rating: 5)
    create(:review, contract: other_completed, reviewer: other_freelancer, reviewee: profile.user, rating: 3)

    freelancer_client = create(:client_profile).user
    freelancer_contract = create(:contract, :completed, job: create(:job, client: freelancer_client), client: freelancer_client, freelancer: profile.user)
    create(:review, contract: freelancer_contract, reviewer: freelancer_client, reviewee: profile.user, rating: 2)

    expect(profile.completed_contracts.count).to eq(3)
    expect(profile.repeat_freelancer_count).to eq(1)
    expect(profile.review_count).to eq(3)
    expect(profile.average_rating).to eq(BigDecimal("4.3333333333333333"))
    expect(profile.low_rating_reviews.count).to eq(1)
    expect(profile.received_reviews).not_to include(freelancer_contract.reviews.first)
  end
end
