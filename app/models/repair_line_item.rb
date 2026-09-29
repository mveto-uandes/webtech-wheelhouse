class RepairLineItem < ApplicationRecord
  belongs_to :repair
  belongs_to :service

  validates :charged_price, presence: true, numericality: { greater_than: 0 }

  scope :oldest_first, -> { order(:created_at, :id) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
end
