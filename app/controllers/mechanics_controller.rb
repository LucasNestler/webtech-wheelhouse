class MechanicsController < ApplicationController
  before_action :set_mechanic, only: [ :show, :edit, :update, :destroy ]

  def index
    @mechanics = Mechanic.by_name
  end

  def show
  end

  def new
    @mechanic = Mechanic.new
  end

  def edit
  end

  def create
    @mechanic = Mechanic.new(mechanic_params)
    if @mechanic.save
      redirect_to @mechanic, notice: "#{@mechanic.name} was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @mechanic.update(mechanic_params)
      redirect_to @mechanic, notice: "#{@mechanic.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @mechanic.destroy
      redirect_to mechanics_path, notice: "#{@mechanic.name} was deleted.", status: :see_other
    else
      redirect_to @mechanic, alert: @mechanic.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_mechanic
    @mechanic = Mechanic.find(params[:id])
  end

  def mechanic_params
    params.expect(mechanic: [ :name, :role ])
  end
end
