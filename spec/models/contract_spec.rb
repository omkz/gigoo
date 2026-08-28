require "rails_helper"

RSpec.describe Contract, type: :model do
  it "defines the expected statuses" do
    expect(described_class.statuses).to eq("active" => 0, "completed" => 1, "cancelled" => 2)
  end

  it "has many reviews" do
    association = described_class.reflect_on_association(:reviews)

    expect(association.macro).to eq(:has_many)
    expect(association.options[:dependent]).to eq(:destroy)
  end

  it "allows only one contract per job" do
    contract = create(:contract)
    duplicate = build(:contract, job: contract.job)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:job_id]).to be_present
  end

  it "enforces one contract per job in the database" do
    contract = create(:contract)
    duplicate = build(:contract, job: contract.job)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "has a unique database index on job_id" do
    index = described_class.connection.indexes(:contracts).find { |candidate| candidate.columns == [ "job_id" ] }

    expect(index.unique).to be(true)
  end

  it "does not allow a negative amount" do
    expect(build(:contract, amount_cents: -1)).not_to be_valid
  end

  it "requires the client to own the job" do
    contract = build(:contract, client: build(:user))

    expect(contract).not_to be_valid
    expect(contract.errors[:client]).to include("must own the job")
  end

  it "requires the freelancer to have a freelancer profile" do
    contract = build(:contract, freelancer: build(:user))

    expect(contract).not_to be_valid
    expect(contract.errors[:freelancer]).to include("must have a freelancer profile")
  end

  it "does not allow the same user to be client and freelancer" do
    job = create(:job)
    create(:freelancer_profile, user: job.client)
    contract = build(:contract, job: job, client: job.client, freelancer: job.client)

    expect(contract).not_to be_valid
    expect(contract.errors[:freelancer]).to include("must be different from client")
  end
end
