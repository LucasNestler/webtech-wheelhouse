class PasswordsController < ApplicationController
  # Listed in docs/decisions.md: an account is not a resource with a policy.
  skip_after_action :verify_authorized
  allow_unauthenticated_access only: %i[ new create edit update ]
  before_action :set_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address].to_s)
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    # has_secure_password ignores a blank password, which would otherwise "succeed" without changing anything.
    if params[:password].present? && @user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: "Password has been reset."
    else
      @user.errors.add(:password, :blank) if params[:password].blank?
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
