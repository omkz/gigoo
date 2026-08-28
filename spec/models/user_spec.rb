require "rails_helper"

RSpec.describe User, type: :model do
  it "keeps the existing role values" do
    expect(described_class.roles).to eq(
      "freelancer" => 0,
      "client" => 1,
      "support" => 2,
      "admin" => 3
    )
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
