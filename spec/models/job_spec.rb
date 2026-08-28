require "rails_helper"

RSpec.describe Job, type: :model do
  it "defines the expected statuses" do
    expect(described_class.statuses).to eq("draft" => 0, "open" => 1, "closed" => 2)
  end

  it "requires its core listing fields" do
    job = build(:job, title: nil, description: nil, budget_cents: nil)

    expect(job).not_to be_valid
    expect(job.errors).to include(:title, :description, :budget_cents)
  end

  it "does not allow a negative budget" do
    expect(build(:job, budget_cents: -1)).not_to be_valid
  end
end
