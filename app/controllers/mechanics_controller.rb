class MechanicsController < ApplicationController
  def index
    @mechanics = Mechanic.by_name
  end

  def show
    @mechanic = Mechanic.find(params[:id])
  end
end
