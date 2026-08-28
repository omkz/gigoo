require "rails_helper"

RSpec.describe JobPolicy do
  describe "marketplace authorization" do
    it "allows a user with a client profile to create jobs" do
      user = create(:client_profile).user

      expect(described_class.new(user, Job)).to be_create
    end

    it "does not allow a user without a client profile to create jobs" do
      expect(described_class.new(create(:user), Job)).not_to be_create
    end

    it "allows only the owner to update, publish, and close a job" do
      job = create(:job)
      other_client = create(:client_profile).user

      owner_policy = described_class.new(job.client, job)
      other_policy = described_class.new(other_client, job)

      expect(owner_policy).to be_update
      expect(owner_policy).to be_publish
      expect(owner_policy).to be_close
      expect(other_policy).not_to be_update
      expect(other_policy).not_to be_publish
      expect(other_policy).not_to be_close
    end

    it "allows only an owning client to view a job's proposals" do
      job = create(:job)
      other_client = create(:client_profile).user

      expect(described_class.new(job.client, job)).to be_proposals
      expect(described_class.new(other_client, job)).not_to be_proposals
      expect(described_class.new(create(:user), job)).not_to be_proposals
    end
  end
end
