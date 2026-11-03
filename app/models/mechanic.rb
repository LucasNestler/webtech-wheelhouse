class Mechanic < ApplicationRecord
  # First, so that a refusal happens before the repairs are touched.
  has_one :user, dependent: :restrict_with_error
  has_many :repair_orders, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true

  scope :by_name, -> { order(:name) }
end
