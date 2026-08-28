require "rails_helper"

RSpec.describe Shortlist, type: :model do
  it "allows a freelancer only once per client and job" do
    shortlist = create(:shortlist)
    duplicate = build(
      :shortlist,
      job: shortlist.job,
      client: shortlist.client,
      freelancer: shortlist.freelancer
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:freelancer_id]).to be_present
  end

  it "enforces shortlist uniqueness in the database" do
    shortlist = create(:shortlist)
    duplicate = build(
      :shortlist,
      job: shortlist.job,
      client: shortlist.client,
      freelancer: shortlist.freelancer
    )

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "requires the client to own the job" do
    shortlist = build(:shortlist, client: build(:user))

    expect(shortlist).not_to be_valid
    expect(shortlist.errors[:client]).to include("must own the job")
  end

  it "requires the freelancer to have a freelancer profile" do
    shortlist = build(:shortlist, freelancer: build(:user))

    expect(shortlist).not_to be_valid
    expect(shortlist.errors[:freelancer]).to include("must have a freelancer profile")
  end
end
