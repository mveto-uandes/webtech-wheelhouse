class RepairLineItem < ApplicationRecord
  belongs_to :repair
  belongs_to :service

  # The messages name the line by its service, so on the repair's form it's
  # clear which line needs fixing.
  validates :charged_price,
    presence: { message: ->(line, _) { "for #{line.line_name} can't be blank" } },
    numericality: { greater_than: 0, allow_nil: true, message: ->(line, _) { "for #{line.line_name} must be more than 0" } }

  scope :oldest_first, -> { order(:created_at, :id) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def line_name
    service&.name || "this line"
  end
end
