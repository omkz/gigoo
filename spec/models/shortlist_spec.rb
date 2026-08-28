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
end
