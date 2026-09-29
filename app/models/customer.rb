class Customer < ApplicationRecord
  has_many :bikes, -> { by_make_and_model }, dependent: :restrict_with_error
  has_many :repair_orders, through: :bikes

  validates :name, presence: true
  validates :phone, presence: true

  scope :by_name, -> { order(:name) }
end
