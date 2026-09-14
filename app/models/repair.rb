class Repair < ApplicationRecord
  belongs_to :bike
  belongs_to :mechanic, class_name: "Employee", foreign_key: :mechanic_id, optional: true

  has_many :repair_line_items
  has_many :payments

  def overdue_and_unpaid?
    return false if promised_on.blank? || !promised_on.past?

    repair_line_items.sum(&:charged_price) > payments.sum(&:amount)
  end
end
