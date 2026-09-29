class Bike < ApplicationRecord
  belongs_to :customer
  has_many :repair_orders
end
