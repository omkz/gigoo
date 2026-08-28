require "rails_helper"

RSpec.describe FreelancerProfile, type: :model do
  it "allows a non-negative hourly rate" do
    expect(build(:freelancer_profile, hourly_rate_cents: 0)).to be_valid
    expect(build(:freelancer_profile, hourly_rate_cents: nil)).to be_valid
    expect(build(:freelancer_profile, hourly_rate_cents: -1)).not_to be_valid
  end

  it "allows only one profile per user" do
    profile = create(:freelancer_profile)

    expect(build(:freelancer_profile, user: profile.user)).not_to be_valid
  end
end
