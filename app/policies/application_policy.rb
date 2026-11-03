# Refuses everything. An action whose policy method has not been written is refused, never allowed.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def new? = false
  def create? = false
  def edit? = false
  def update? = false
  def destroy? = false

  # The attributes this person may write.
  def permitted_attributes = []

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve = scope.none

    private

    attr_reader :user, :scope

    def owner? = user.present? && user.role_owner?
    def counter? = user.present? && user.role_counter?
    def mechanic? = user.present? && user.role_mechanic?
    def front_desk? = owner? || counter?
  end

  private

  def signed_in? = user.present?
  def owner? = signed_in? && user.role_owner?
  def counter? = signed_in? && user.role_counter?
  def mechanic? = signed_in? && user.role_mechanic?
  def front_desk? = owner? || counter?
end
