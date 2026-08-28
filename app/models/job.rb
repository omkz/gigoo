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

  def budget
    BigDecimal(budget_cents.to_s) / 100 if budget_cents.present?
  end

  def budget=(value)
    self.budget_cents = value.present? ? (BigDecimal(value.to_s) * 100).round.to_i : nil
  rescue ArgumentError
    self.budget_cents = nil
  end

  private

  def client_has_client_profile
    errors.add(:client, "must have a client profile") if client.present? && client.client_profile.blank?
  end
end
