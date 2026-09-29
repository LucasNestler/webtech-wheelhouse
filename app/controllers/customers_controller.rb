class CustomersController < ApplicationController
  def index
    @customers = Customer.order(:name)
  end

  def show
    @customer = Customer.find(params[:id])
  end
end
