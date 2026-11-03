class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # An action that forgets to ask the policy raises, and so does an index not built from a scope.
  # A new controller is covered without a line written in it.
  after_action :verify_authorized
  # A condition, not only: :index. Not every controller has an index, and this app raises on a missing callback action.
  after_action :verify_policy_scoped, if: -> { action_name == "index" }

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  # The public pages skip require_authentication, so the session may not have been read yet.
  def pundit_user
    Current.user if authenticated?
  end

  def render_forbidden
    render "errors/forbidden", status: :forbidden, formats: [ :html ]
  end
end
