class WelcomeMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail subject: "Welcome to Wheelhouse", to: user.email_address
  end
end
