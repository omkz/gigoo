require "rails_helper"

RSpec.describe WorkPolicy do
  it "allows only users with freelancer capability" do
    freelancer = create(:freelancer_profile).user

    expect(described_class.new(freelancer, :work)).to be_show
    expect(described_class.new(create(:user), :work)).not_to be_show
    expect(described_class.new(nil, :work)).not_to be_show
  end
end
