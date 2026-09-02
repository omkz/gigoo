require "rails_helper"

RSpec.describe FreelancerProfilePolicy do
  it "allows only the profile owner to edit and update" do
    profile = create(:freelancer_profile)

    expect(described_class.new(profile.user, profile)).to be_edit
    expect(described_class.new(profile.user, profile)).to be_update
    expect(described_class.new(create(:user), profile)).not_to be_update
  end
end
