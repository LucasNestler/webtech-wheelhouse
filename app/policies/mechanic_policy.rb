# The staff pages.
class MechanicPolicy < ApplicationPolicy
  def index? = signed_in?
  def show? = signed_in?

  def new? = owner?
  def create? = owner?
  def edit? = owner?
  def update? = owner?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve = user.present? ? scope.all : scope.none
  end
end
