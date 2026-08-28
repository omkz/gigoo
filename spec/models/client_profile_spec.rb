require "rails_helper"

RSpec.describe ClientProfile, type: :model do
  it "belongs to a user" do
    expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
  end

  it "allows only one profile per user" do
    profile = create(:client_profile)

    expect(build(:client_profile, user: profile.user)).not_to be_valid
  end
end
