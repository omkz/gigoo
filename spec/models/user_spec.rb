require "rails_helper"

RSpec.describe User, type: :model do
  it "uses roles only for system-level privileges" do
    expect(described_class.roles).to eq(
      "member" => 0,
      "support" => 1,
      "admin" => 2
    )
  end

  it "can have both marketplace profiles as a member" do
    user = create(:user)
    create(:client_profile, user: user)
    create(:freelancer_profile, user: user)

    expect(user).to be_member
    expect(user.client_profile).to be_present
    expect(user.freelancer_profile).to be_present
  end

  it "exposes the marketplace associations" do
    expect(described_class.reflect_on_association(:client_profile).macro).to eq(:has_one)
    expect(described_class.reflect_on_association(:freelancer_profile).macro).to eq(:has_one)
    expect(described_class.reflect_on_association(:posted_jobs).class_name).to eq("Job")
    expect(described_class.reflect_on_association(:proposals).foreign_key).to eq("freelancer_id")
    expect(described_class.reflect_on_association(:client_contracts).foreign_key).to eq("client_id")
    expect(described_class.reflect_on_association(:freelancer_contracts).foreign_key).to eq("freelancer_id")
    expect(described_class.reflect_on_association(:reviews_given).foreign_key).to eq("reviewer_id")
    expect(described_class.reflect_on_association(:reviews_received).foreign_key).to eq("reviewee_id")
    expect(described_class.reflect_on_association(:shortlists).foreign_key).to eq("client_id")
    expect(described_class.reflect_on_association(:shortlist_entries).foreign_key).to eq("freelancer_id")
  end
end
