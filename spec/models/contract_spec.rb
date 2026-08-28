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
end
