class RepairOrderPolicy < ApplicationPolicy
  MECHANIC_ATTRIBUTES = [ :status, :diagnosis, { intake_photos: [] } ].freeze
  FRONT_DESK_ATTRIBUTES = [
    :bike_id, :mechanic_id, :status, :promised_on,
    :quoted_at, :quote_accepted, :completed_at, :picked_up_at, :diagnosis,
    { intake_photos: [], repair_line_items_attributes: [ :id, :service_id, :charged_price, :_destroy ] }
  ].freeze

  # Open to every account: what each one finds in the list is decided by the scope.
  def index? = signed_in?
  def show? = front_desk? || own?

  def new? = front_desk?
  def create? = front_desk?

  def edit? = update?
  def update? = owner? || (not_handed_back? && (counter? || own?))

  def destroy? = owner?

  # Mechanics add photos, and removing one is not among the things they change.
  def remove_photo? = owner? || (counter? && not_handed_back?)

  def permitted_attributes
    front_desk? ? FRONT_DESK_ATTRIBUTES : MECHANIC_ATTRIBUTES
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if front_desk?
      return scope.where(mechanic_id: user.mechanic_id) if mechanic? && user.mechanic_id.present?

      # Without this, a mechanic with no member of the staff would match the unassigned repairs.
      scope.none
    end
  end

  private

  def not_handed_back? = !record.picked_up?

  # The same answer as the scope: an account with no member of the staff has no repairs of its own.
  def own? = mechanic? && user.mechanic_id.present? && record.mechanic_id == user.mechanic_id
end
