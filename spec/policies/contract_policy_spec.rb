require "rails_helper"

RSpec.describe ContractPolicy do
  it "allows only the contract client with a client profile to view it" do
    contract = create(:contract)
    other_client = create(:client_profile).user

    expect(described_class.new(contract.client, contract)).to be_show
    expect(described_class.new(other_client, contract)).not_to be_show
    expect(described_class.new(create(:user), contract)).not_to be_show
  end

  %i[ support admin ].each do |role|
    it "does not give #{role} an ownership bypass" do
      contract = create(:contract)
      privileged_user = create(:user, role: role)
      create(:client_profile, user: privileged_user)

      expect(described_class.new(privileged_user, contract)).not_to be_show
    end
  end
end
