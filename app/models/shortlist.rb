class Shortlist < ApplicationRecord
  belongs_to :job
  belongs_to :client, class_name: "User"
  belongs_to :freelancer, class_name: "User"

  validates :freelancer_id, uniqueness: { scope: [ :job_id, :client_id ] }
end
