class Employee < ApplicationRecord
  ROLES = %w[owner mechanic counter].freeze

  # Checked first, so a refused destroy leaves the repairs untouched.
  has_one :user, dependent: :restrict_with_error
  has_many :repairs, foreign_key: :mechanic_id, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true

  scope :by_name, -> { order(:name) }
  scope :mechanics, -> { where(role: "mechanic") }
end
