class Employee < ApplicationRecord
  has_many :repairs, foreign_key: :mechanic_id, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true

  scope :by_name, -> { order(:name) }
  scope :mechanics, -> { where(role: "mechanic") }
end
