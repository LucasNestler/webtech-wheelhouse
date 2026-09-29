class BikesController < ApplicationController
  def index
    @bikes = Bike.order(:make, :model)
  end

  def show
    @bike = Bike.find(params[:id])
  end
end
