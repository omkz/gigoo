require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:valid_attributes) do
    {
      first_name: "Kurnia",
      last_name: "Muhamad",
      email_address: "kurnia@example.com",
      password: "password",
      password_confirmation: "password"
    }
  end

  it "allows a visitor to view the signup page" do
    get sign_up_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Create an account")
  end

  it "creates and authenticates a member with valid data" do
    expect do
      post sign_up_path, params: { user: valid_attributes }
    end.to change(User, :count).by(1).and change(Session, :count).by(1)

    user = User.order(:created_at).last
    expect(user.first_name).to eq("Kurnia")
    expect(user.last_name).to eq("Muhamad")
    expect(user).to be_member
    expect(Session.order(:created_at).last.user).to eq(user)
    expect(response).to redirect_to(root_path)

    follow_redirect!
    expect(response.body).to include("Sign out")
  end

  it "rejects a duplicate email address" do
    create(:user, email_address: valid_attributes[:email_address])

    expect do
      post sign_up_path, params: { user: valid_attributes }
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Email address has already been taken")
  end

  it "rejects a blank or invalid email address" do
    [ "", "not-an-email" ].each do |email_address|
      expect do
        post sign_up_path, params: { user: valid_attributes.merge(email_address: email_address) }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "rejects a blank first name" do
    expect do
      post sign_up_path, params: { user: valid_attributes.merge(first_name: "") }
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("First name can&#39;t be blank")
  end

  it "rejects a blank last name" do
    expect do
      post sign_up_path, params: { user: valid_attributes.merge(last_name: "") }
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Last name can&#39;t be blank")
  end

  it "rejects a password confirmation mismatch" do
    expect do
      post sign_up_path, params: { user: valid_attributes.merge(password_confirmation: "different") }
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Password confirmation doesn&#39;t match Password")
  end

  it "ignores attempts to spoof privileged system roles" do
    %i[ admin support ].each_with_index do |role, index|
      post sign_up_path, params: {
        user: valid_attributes.merge(email_address: "spoof#{index}@example.com", role: role)
      }

      expect(User.order(:created_at).last).to be_member
    end
  end
end
