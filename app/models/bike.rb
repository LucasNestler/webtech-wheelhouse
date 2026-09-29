class Bike < ApplicationRecord
  belongs_to :customer
  has_many :repair_orders, -> { by_promised_date }, dependent: :destroy

  before_validation :normalize_serial_number

  validates :serial_number, presence: true, uniqueness: true
  validates :make, presence: true
  validates :model, presence: true
  validates :color, presence: true

  scope :by_make_and_model, -> { order(:make, :model) }

  private

  def normalize_serial_number
    self.serial_number = serial_number.strip.upcase if serial_number.present?
  end
end
