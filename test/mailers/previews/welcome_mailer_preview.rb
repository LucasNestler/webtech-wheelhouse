# Preview all emails at http://localhost:3000/rails/mailers/welcome_mailer
class WelcomeMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/welcome_mailer/welcome
  def welcome
    WelcomeMailer.welcome(User.new(email_address: "new.person@wheelhouse.example"))
  end
end
