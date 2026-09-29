class RepairLineItem < ApplicationRecord
  belongs_to :repair_order
  belongs_to :service
end
