class RepairOrdersController < ApplicationController
  before_action :set_repair_order, only: [ :show, :edit, :update, :destroy ]

  NEW_REPAIR_BLANK_LINES = 3
  EDIT_REPAIR_EXTRA_BLANK_LINES = 2

  def index
    @repair_orders = RepairOrder.includes(bike: :customer).by_promised_date
  end

  def show
  end

  def new
    @repair_order = RepairOrder.new(bike_id: params[:bike_id])
    NEW_REPAIR_BLANK_LINES.times { @repair_order.repair_line_items.build }
    load_form_collections
  end

  def edit
    EDIT_REPAIR_EXTRA_BLANK_LINES.times { @repair_order.repair_line_items.build }
    load_form_collections
  end

  def create
    @repair_order = RepairOrder.new(repair_order_params)
    if @repair_order.save
      redirect_to @repair_order, notice: "Repair ##{@repair_order.id} was added."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @repair_order.update(repair_order_params)
      redirect_to @repair_order, notice: "Repair ##{@repair_order.id} was updated."
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @repair_order.destroy
      redirect_to repair_orders_path, notice: "Repair ##{@repair_order.id} was deleted.", status: :see_other
    else
      redirect_to @repair_order, alert: @repair_order.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_repair_order
    @repair_order = RepairOrder.includes(:mechanic, bike: :customer, repair_line_items: :service).find(params[:id])
  end

  def load_form_collections
    @bikes = Bike.includes(:customer).by_make_and_model
    @mechanics = Mechanic.by_name
    @services = Service.by_name
  end

  def repair_order_params
    params.expect(repair_order: [
      :bike_id, :mechanic_id, :status, :promised_on,
      :quoted_at, :quote_accepted, :completed_at, :picked_up_at,
      repair_line_items_attributes: [ [ :id, :service_id, :charged_price, :_destroy ] ]
    ])
  end
end
