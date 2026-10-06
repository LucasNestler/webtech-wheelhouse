class IntakePhotosController < ApplicationController
  def destroy
    repair_order = RepairOrder.find(params[:repair_order_id])
    photo = repair_order.intake_photos.find(params[:id])
    photo.purge
    redirect_back_or_to repair_order, notice: "Photo removed.", status: :see_other
  end
end
