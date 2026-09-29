class Customer < ApplicationRecord
  has_many :bikes, dependent: :restrict_with_error
  has_many :repairs, through: :bikes, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true
  validates :phone, presence: true

  scope :by_name, -> { order(:name) }
end
