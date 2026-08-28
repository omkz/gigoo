require "rails_helper"

RSpec.describe Review, type: :model do
  it "accepts ratings from one through five" do
    expect(build(:review, rating: 1)).to be_valid
    expect(build(:review, rating: 5)).to be_valid
  end

  it "rejects ratings outside one through five" do
    expect(build(:review, rating: 0)).not_to be_valid
    expect(build(:review, rating: 6)).not_to be_valid
  end

  it "allows the client to review the freelancer" do
    review = build(:review)

    expect(review).to be_valid
  end

  it "allows the freelancer to review the client" do
    contract = build(:contract, :completed)
    review = build(:review, contract: contract, reviewer: contract.freelancer, reviewee: contract.client)

    expect(review).to be_valid
  end

  it "does not allow the client to review themselves" do
    contract = build(:contract, :completed)
    review = build(:review, contract: contract, reviewer: contract.client, reviewee: contract.client)

    expect(review).not_to be_valid
    expect(review.errors[:reviewer]).to include("cannot review themselves")
  end

  it "does not allow the freelancer to review themselves" do
    contract = build(:contract, :completed)
    review = build(:review, contract: contract, reviewer: contract.freelancer, reviewee: contract.freelancer)

    expect(review).not_to be_valid
    expect(review.errors[:reviewer]).to include("cannot review themselves")
  end

  it "does not allow an unrelated user to review either contract party" do
    contract = build(:contract, :completed)
    unrelated_user = build(:user)
    reviews = [ contract.client, contract.freelancer ].map do |reviewee|
      build(:review, contract: contract, reviewer: unrelated_user, reviewee: reviewee)
    end

    reviews.each do |review|
      expect(review).not_to be_valid
      expect(review.errors[:reviewer]).to include("must be a party to the contract")
    end
  end

  it "does not allow the client to review a third user" do
    contract = build(:contract, :completed)
    review = build(:review, contract: contract, reviewer: contract.client, reviewee: build(:user))

    expect(review).not_to be_valid
    expect(review.errors[:reviewee]).to include("must be the other party to the contract")
  end

  it "does not allow the freelancer to review a third user" do
    contract = build(:contract, :completed)
    review = build(:review, contract: contract, reviewer: contract.freelancer, reviewee: build(:user))

    expect(review).not_to be_valid
    expect(review.errors[:reviewee]).to include("must be the other party to the contract")
  end

  it "requires the contract to be completed" do
    review = build(:review, contract: build(:contract, status: :active))

    expect(review).not_to be_valid
    expect(review.errors[:contract]).to include("must be completed")
  end

  it "allows only one review per reviewer and contract" do
    review = create(:review)
    duplicate = build(:review, contract: review.contract, reviewer: review.reviewer)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:reviewer_id]).to be_present
  end

  it "enforces review uniqueness in the database" do
    review = create(:review)
    duplicate = build(:review, contract: review.contract, reviewer: review.reviewer)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
