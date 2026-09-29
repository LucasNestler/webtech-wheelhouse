class RepairOrder < ApplicationRecord
  belongs_to :bike
  belongs_to :mechanic, optional: true
  has_many :repair_line_items
end
