class BikePolicy < ApplicationPolicy
  def index? = front_desk?
  def show? = front_desk?
  def new? = front_desk?
  def create? = front_desk?
  def edit? = front_desk?
  def update? = front_desk?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve = front_desk? ? scope.all : scope.none
  end
end
