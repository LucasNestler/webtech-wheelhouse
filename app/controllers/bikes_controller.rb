class BikesController < ApplicationController
  before_action :set_bike, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Bike
    @bikes = policy_scope(Bike).includes(:customer).by_make_and_model
  end

  def show
    @repair_orders = policy_scope(@bike.repair_orders).includes(bike: :customer, taken_in_by: :mechanic).with_attached_intake_photos.with_rich_text_diagnosis
  end

  def new
    authorize Bike
    @bike = Bike.new(customer_id: params[:customer_id])
    @customers = Customer.by_name
  end

  def edit
    @customers = Customer.by_name
  end

  def create
    authorize Bike
    @bike = Bike.new(bike_params)
    if @bike.save
      redirect_to @bike, notice: "#{@bike.serial_number} was added."
    else
      @customers = Customer.by_name
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @bike.update(bike_params)
      redirect_to @bike, notice: "#{@bike.serial_number} was updated."
    else
      @customers = Customer.by_name
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @bike.destroy
      redirect_to bikes_path, notice: "#{@bike.serial_number} was deleted.", status: :see_other
    else
      redirect_to @bike, alert: @bike.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_bike
    @bike = Bike.includes(:customer).find(params[:id])
    authorize @bike
  end

  def bike_params
    params.expect(bike: [ :serial_number, :make, :model, :color, :customer_id ])
  end
end
