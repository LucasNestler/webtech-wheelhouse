class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Wheelhouse: reset your password", to: user.email_address
  end
end
