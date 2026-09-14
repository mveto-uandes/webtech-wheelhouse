class Repair < ApplicationRecord
  belongs_to :bike
  belongs_to :mechanic, class_name: "Employee", foreign_key: :mechanic_id, optional: true

  has_many :repair_line_items
  has_many :payments
end
