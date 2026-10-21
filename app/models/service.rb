class Service < ApplicationRecord
  has_many :repair_line_items, dependent: :restrict_with_error
  has_many :repairs, through: :repair_line_items, dependent: :restrict_with_error

  # A null byte can't be stored in a PostgreSQL string, so it's dropped too.
  normalizes :name, with: ->(name) { name.delete("\u0000").squish }

  validates :name, presence: true, uniqueness: true
  # The column is decimal(8,2): a price of a million or more doesn't fit in it.
  validates :price, presence: true, numericality: { greater_than: 0, less_than: 1_000_000 }

  scope :by_name, -> { order(:name) }
end
