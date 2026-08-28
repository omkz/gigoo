class Job < ApplicationRecord
  belongs_to :client, class_name: "User"

  has_many :proposals, dependent: :destroy
  has_many :shortlists, dependent: :destroy

  enum :status, { draft: 0, open: 1, closed: 2 }

  validates :title, :description, presence: true
  validates :budget_cents,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :client_has_client_profile

  private

  def client_has_client_profile
    errors.add(:client, "must have a client profile") if client.present? && client.client_profile.blank?
  end
end
