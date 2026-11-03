class ServicePolicy < ApplicationPolicy
  # The price list is public: user is nil for a visitor.
  def index? = true
  def show? = true

  def new? = owner?
  def create? = owner?
  def edit? = owner?
  def update? = owner?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
