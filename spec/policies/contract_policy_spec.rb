require "rails_helper"

RSpec.describe ContractPolicy do
  it "allows only the contract client with a client profile to use the client view" do
    contract = create(:contract)
    other_client = create(:client_profile).user

    expect(described_class.new(contract.client, contract)).to be_show_client
    expect(described_class.new(other_client, contract)).not_to be_show_client
    expect(described_class.new(create(:user), contract)).not_to be_show_client
  end

  it "allows only the contract freelancer to use the freelancer view" do
    contract = create(:contract)

    expect(described_class.new(contract.freelancer, contract)).to be_show_freelancer
    expect(described_class.new(create(:freelancer_profile).user, contract)).not_to be_show_freelancer
  end

  it "allows the client to complete only an active contract" do
    active_contract = create(:contract, status: :active)
    completed_contract = create(:contract, :completed)
    cancelled_contract = create(:contract, status: :cancelled)

    expect(described_class.new(active_contract.client, active_contract)).to be_complete
    expect(described_class.new(completed_contract.client, completed_contract)).not_to be_complete
    expect(described_class.new(cancelled_contract.client, cancelled_contract)).not_to be_complete
  end

  %i[ support admin ].each do |role|
    it "does not give #{role} an ownership bypass" do
      contract = create(:contract)
      privileged_user = create(:user, role: role)
      create(:client_profile, user: privileged_user)

      expect(described_class.new(privileged_user, contract)).not_to be_show_client
      expect(described_class.new(privileged_user, contract)).not_to be_complete
    end
  end
end
