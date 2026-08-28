class User < ApplicationRecord
  enum :role, {
    freelancer: 0,
    client: 1,
    support: 2,
    admin: 3
  }

  has_one :client_profile, dependent: :destroy
  has_one :freelancer_profile, dependent: :destroy

  has_many :posted_jobs, class_name: "Job", foreign_key: :client_id, inverse_of: :client, dependent: :destroy
  has_many :proposals, foreign_key: :freelancer_id, inverse_of: :freelancer, dependent: :destroy
  has_many :client_contracts, class_name: "Contract", foreign_key: :client_id, inverse_of: :client, dependent: :destroy
  has_many :freelancer_contracts, class_name: "Contract", foreign_key: :freelancer_id, inverse_of: :freelancer, dependent: :destroy
  has_many :reviews_given, class_name: "Review", foreign_key: :reviewer_id, inverse_of: :reviewer, dependent: :destroy
  has_many :reviews_received, class_name: "Review", foreign_key: :reviewee_id, inverse_of: :reviewee, dependent: :destroy
  has_many :shortlists, foreign_key: :client_id, inverse_of: :client, dependent: :destroy
  has_many :shortlist_entries, class_name: "Shortlist", foreign_key: :freelancer_id, inverse_of: :freelancer, dependent: :destroy
end
