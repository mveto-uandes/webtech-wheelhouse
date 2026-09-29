class Repair < ApplicationRecord
  belongs_to :bike
  belongs_to :mechanic, class_name: "Employee", foreign_key: :mechanic_id, optional: true

  has_many :payments, dependent: :restrict_with_error
  has_many :repair_line_items, dependent: :destroy
  has_many :services, through: :repair_line_items, dependent: :destroy

  # Lines are written through the repair's form. A line left without a service
  # is an unused blank row, not a mistake.
  accepts_nested_attributes_for :repair_line_items,
    allow_destroy: true,
    reject_if: ->(attributes) { attributes["service_id"].blank? && attributes["id"].blank? }

  enum :status, {
    received: "received",
    diagnosing: "diagnosing",
    quoted: "quoted",
    approved: "approved",
    declined: "declined",
    in_repair: "in_repair",
    ready_for_pickup: "ready_for_pickup",
    completed: "completed"
  }

  validates :reported_problem, presence: true
  validates :status, presence: true
  validate :dates_not_before_intake
  validate :hand_back_matches_state
  validate :approval_on_file

  scope :in_shop, -> { where(handed_back_at: nil) }
  scope :overdue, -> { in_shop.where(promised_on: ...Date.current) }
  scope :by_promised_on, -> { order(:promised_on, :id) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def overdue?
    handed_back_at.nil? && promised_on.present? && promised_on < Date.current
  end

  def total
    repair_line_items.sum(&:charged_price)
  end

  private

  def intake_date
    (created_at || Time.current).to_date
  end

  def dates_not_before_intake
    if promised_on.present? && promised_on < intake_date
      errors.add(:promised_on, "can't be before the day the bike came in")
    end
    if handed_back_at.present? && handed_back_at.to_date < intake_date
      errors.add(:handed_back_at, "can't be before the day the bike came in")
    end
  end

  def hand_back_matches_state
    if handed_back_at.present? && !completed?
      errors.add(:handed_back_at, "can only be filled in once the repair is completed")
    end
  end

  # The customer's yes is the quote they accepted: the services on the repair.
  def approval_on_file
    return unless in_repair? || ready_for_pickup? || completed?
    return if repair_line_items.any? { |item| !item.marked_for_destruction? }

    errors.add(:status, "can't move past the quote until the customer's approved services are on the repair")
  end
end
