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
end
