class ServicesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_service, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Service
    @services = policy_scope(Service).by_name
  end

  def show
  end

  def new
    authorize Service
    @service = Service.new
  end

  def edit
  end

  def create
    authorize Service
    @service = Service.new(service_params)
    if @service.save
      redirect_to @service, notice: "#{@service.name} was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @service.update(service_params)
      redirect_to @service, notice: "#{@service.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @service.destroy
      redirect_to services_path, notice: "#{@service.name} was deleted.", status: :see_other
    else
      redirect_to @service, alert: @service.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_service
    @service = Service.find(params[:id])
    authorize @service
  end

  def service_params
    params.expect(service: [ :name, :default_price, :active ])
  end
end
