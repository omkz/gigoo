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

  it "does not allow a reviewer to review themselves" do
    review = build(:review)
    review.reviewee = review.reviewer

    expect(review).not_to be_valid
    expect(review.errors[:reviewer]).to include("cannot review themselves")
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
