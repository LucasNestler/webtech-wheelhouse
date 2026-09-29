class Mechanic < ApplicationRecord
  has_many :repair_orders, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true

  scope :by_name, -> { order(:name) }
end
