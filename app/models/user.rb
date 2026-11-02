class User < ApplicationRecord
  # Long enough that a guessed word or a date doesn't make it.
  PASSWORD_MIN_LENGTH = 10

  has_secure_password
  has_many :sessions, dependent: :destroy
  # Repairs keep their history: an account that goes leaves them with nobody.
  has_many :taken_in_repairs, class_name: "Repair", foreign_key: :taken_in_by_id,
    inverse_of: :taken_in_by, dependent: :nullify

  belongs_to :employee, optional: true

  # Mechanic is the default because it can do the least (docs/decisions.md).
  enum :role, { owner: "owner", mechanic: "mechanic", counter: "counter" }, default: :mechanic

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validates :employee_id, uniqueness: { allow_nil: true }
  validates :role, presence: true
  # A blank password would be ignored by has_secure_password and leave the old
  # one in place, so a password that is being set can't be blank either.
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true

  # How the rest of the app names the account: the person, or the address.
  def display_name
    employee&.name || email_address
  end
end
