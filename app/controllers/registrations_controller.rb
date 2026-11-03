class RegistrationsController < ApplicationController
  # Listed in docs/decisions.md: an account is not a resource with a policy.
  skip_after_action :verify_authorized
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      WelcomeMailer.welcome(@user).deliver_later
      redirect_to after_authentication_url, notice: "Welcome to Wheelhouse."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # Two sign-ups with one address at the same moment: the index refused what the validation could not see.
    @user.errors.add(:email_address, :taken)
    render :new, status: :unprocessable_entity
  end

  private

  # No role and no member of the staff: those are set from the seed or the console.
  def registration_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end
