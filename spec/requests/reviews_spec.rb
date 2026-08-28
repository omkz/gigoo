require "rails_helper"

RSpec.describe "Reviews", type: :request do
  def sign_in(user)
    session = Session.create!(user: user, user_agent: "RSpec", ip_address: "127.0.0.1")
    get new_session_path
    cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    cookie_jar.signed[:session_id] = session.id
    cookies[:session_id] = cookie_jar[:session_id]
  end

  it "derives the client reviewer and freelancer reviewee" do
    contract = create(:contract, :completed)
    spoofed_reviewer = create(:user)
    spoofed_reviewee = create(:user)
    sign_in(contract.client)

    expect do
      post contract_reviews_path(contract), params: {
        review: {
          rating: 5,
          body: "Excellent Rails work and communication.",
          reviewer_id: spoofed_reviewer.id,
          reviewee_id: spoofed_reviewee.id
        }
      }
    end.to change(Review, :count).by(1)

    review = Review.order(:created_at).last
    expect(review.reviewer).to eq(contract.client)
    expect(review.reviewee).to eq(contract.freelancer)
    expect(review.rating).to eq(5)
    expect(review.body).to eq("Excellent Rails work and communication.")
    expect(response).to redirect_to(client_contract_path(contract))
  end

  it "allows the freelancer to review the client independently" do
    contract = create(:contract, :completed)
    create(:review, contract: contract, reviewer: contract.client, reviewee: contract.freelancer)
    sign_in(contract.freelancer)

    expect do
      post contract_reviews_path(contract), params: { review: { rating: 4, body: "Clear scope and prompt feedback." } }
    end.to change(Review, :count).by(1)

    review = contract.reviews.find_by!(reviewer: contract.freelancer)
    expect(review.reviewee).to eq(contract.client)
    expect(response).to redirect_to(freelancer_contract_path(contract))
  end

  it "rejects duplicate reviews from either party" do
    contract = create(:contract, :completed)
    create(:review, contract: contract, reviewer: contract.client, reviewee: contract.freelancer)
    create(:review, contract: contract, reviewer: contract.freelancer, reviewee: contract.client)

    [ contract.client, contract.freelancer ].each do |reviewer|
      sign_in(reviewer)

      expect do
        post contract_reviews_path(contract), params: { review: { rating: 5, body: "Duplicate" } }
      end.not_to change(Review, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  it "forbids an unrelated user" do
    contract = create(:contract, :completed)
    sign_in(create(:user))

    post contract_reviews_path(contract), params: { review: { rating: 5, body: "Not my contract" } }

    expect(response).to have_http_status(:forbidden)
    expect(contract.reviews).to be_empty
  end

  %i[ active cancelled ].each do |status|
    it "does not allow a review for a #{status} contract" do
      contract = create(:contract, status: status)
      sign_in(contract.client)

      post contract_reviews_path(contract), params: { review: { rating: 5, body: "Too early" } }

      expect(response).to have_http_status(:forbidden)
      expect(contract.reviews).to be_empty
    end
  end

  it "rejects ratings outside one through five without persisting a review" do
    [ 0, 6 ].each do |rating|
      contract = create(:contract, :completed)
      sign_in(contract.client)

      expect do
        post contract_reviews_path(contract), params: { review: { rating: rating, body: "Invalid rating" } }
      end.not_to change(Review, :count)

      expect(response).to redirect_to(client_contract_path(contract))
    end
  end
end
