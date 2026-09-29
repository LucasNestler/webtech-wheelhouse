class RepairLineItem < ApplicationRecord
  belongs_to :repair_order
  belongs_to :service

  validates :charged_price, presence: true, numericality: { greater_than: 0 }

  scope :oldest_first, -> { order(:created_at) }
end
