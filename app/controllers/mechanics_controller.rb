class MechanicsController < ApplicationController
  def index
    @mechanics = Mechanic.order(:name)
  end

  def show
    @mechanic = Mechanic.find(params[:id])
  end
end
