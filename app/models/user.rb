class User < ApplicationRecord
  PASSWORD_MINIMUM_LENGTH = 10

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :mechanic, optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # The prefix keeps user.role_mechanic? (the role) apart from user.mechanic (the member of the staff).
  # The default of the column is the role with the fewest permissions: see docs/decisions.md.
  enum :role, { owner: "owner", mechanic: "mechanic", counter: "counter" }, prefix: true

  validates :email_address, presence: true,
    format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validates :password, length: { minimum: PASSWORD_MINIMUM_LENGTH }, allow_nil: true
  # has_secure_password skips the match when the confirmation is left out of the request.
  validates :password_confirmation, presence: true, if: -> { password.present? }

  # The name of the person, or the address for an account that belongs to nobody on the staff.
  def display_name
    mechanic&.name || email_address
  end
end
