class Payment < ApplicationRecord
  belongs_to :repair

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :method, presence: true
  validates :paid_at, presence: true

  scope :newest_first, -> { order(paid_at: :desc, id: :desc) }
  scope :oldest_first, -> { order(:paid_at, :id) }
end
