# The pages with no model (home, visit, about): open to every account.
class PagePolicy < ApplicationPolicy
  def home? = signed_in?
  def visit? = signed_in?
  def about? = signed_in?
end
