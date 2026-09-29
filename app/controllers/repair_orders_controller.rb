class RepairOrdersController < ApplicationController
  def index
    @repair_orders = RepairOrder.order(:promised_on)
  end

  def show
    @repair_order = RepairOrder.find(params[:id])
  end
end
