class RepairOrdersController < ApplicationController
  before_action :set_repair_order, only: [ :show, :edit, :update, :destroy ]

  NEW_REPAIR_BLANK_LINES = 3
  EDIT_REPAIR_EXTRA_BLANK_LINES = 2

  def index
    authorize RepairOrder
    repairs = policy_scope(RepairOrder).includes(bike: :customer, taken_in_by: :mechanic)
      .with_attached_intake_photos.with_rich_text_diagnosis.by_promised_date
    repairs = repairs.where(status: params[:state]) if RepairOrder.statuses.key?(params[:state])
    repairs = repairs.overdue if params[:overdue].present?
    @repair_orders = repairs
  end

  def show
  end

  def new
    authorize RepairOrder
    @repair_order = RepairOrder.new(bike_id: params[:bike_id])
    NEW_REPAIR_BLANK_LINES.times { @repair_order.repair_line_items.build }
    load_form_collections
  end

  def edit
    EDIT_REPAIR_EXTRA_BLANK_LINES.times { @repair_order.repair_line_items.build }
    load_form_collections
  end

  def create
    authorize RepairOrder
    @repair_order = RepairOrder.new(permitted_attributes(RepairOrder))
    @repair_order.taken_in_by = Current.user
    if @repair_order.save
      redirect_to @repair_order, notice: "Repair ##{@repair_order.id} was added."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @repair_order.update(permitted_attributes(@repair_order))
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
    @repair_order = RepairOrder.includes(:mechanic, bike: :customer, repair_line_items: :service, taken_in_by: :mechanic)
      .with_attached_intake_photos.with_rich_text_diagnosis.find(params[:id])
    authorize @repair_order
  end

  def load_form_collections
    @bikes = policy_scope(Bike).includes(:customer).by_make_and_model
    @mechanics = Mechanic.by_name
    @services = Service.by_name
  end
end
