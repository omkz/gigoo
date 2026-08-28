require "rails_helper"

RSpec.describe ShortlistPolicy do
  it "allows an owning client to create and destroy shortlist entries" do
    shortlist = build(:shortlist)
    policy = described_class.new(shortlist.client, shortlist)

    expect(policy).to be_create
    expect(policy).to be_destroy
  end

  it "rejects users without a client profile and non-owners" do
    shortlist = build(:shortlist)

    expect(described_class.new(build(:user), shortlist)).not_to be_create
    expect(described_class.new(create(:client_profile).user, shortlist)).not_to be_create
  end

  it "rejects self-shortlisting" do
    job = create(:job)
    create(:freelancer_profile, user: job.client)
    shortlist = build(:shortlist, job: job, client: job.client, freelancer: job.client)

    expect(described_class.new(job.client, shortlist)).not_to be_create
  end

  it "rejects a user without a freelancer profile" do
    job = build(:job)
    shortlist = build(:shortlist, job: job, client: job.client, freelancer: build(:user))

    expect(described_class.new(job.client, shortlist)).not_to be_create
  end

  %i[ support admin ].each do |role|
    it "does not give #{role} automatic access to another client's shortlist" do
      shortlist = build(:shortlist)
      privileged_user = create(:user, role: role)
      create(:client_profile, user: privileged_user)
      policy = described_class.new(privileged_user, shortlist)

      expect(policy).not_to be_create
      expect(policy).not_to be_destroy
    end
  end
end
