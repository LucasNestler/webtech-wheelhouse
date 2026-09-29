class RepairOrdersController < ApplicationController
  def index
    @repair_orders = RepairOrder.includes(bike: :customer).by_promised_date
  end

  def show
    @repair_order = RepairOrder.includes(:mechanic, bike: :customer, repair_line_items: :service).find(params[:id])
  end
end
