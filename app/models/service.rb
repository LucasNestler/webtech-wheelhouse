class Service < ApplicationRecord
  has_many :repair_line_items, dependent: :restrict_with_error
  has_many :repair_orders, through: :repair_line_items

  before_validation :normalize_name

  validates :name, presence: true, uniqueness: true
  validates :default_price, presence: true, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [ true, false ], message: "must be set" }

  scope :by_name, -> { order(:name) }

  private

  def normalize_name
    self.name = name.strip if name.present?
  end
end
