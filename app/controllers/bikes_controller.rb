class BikesController < ApplicationController
  def index
    @bikes = Bike.includes(:customer).by_make_and_model
  end

  def show
    @bike = Bike.includes(:customer, repair_orders: { bike: :customer }).find(params[:id])
  end
end
