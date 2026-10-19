class Repair < ApplicationRecord
  # What the shop's phones produce: JPEG and PNG, and WebP from some Android
  # cameras. iPhones turn their HEIC photos into JPEG when a browser uploads them.
  INTAKE_PHOTO_TYPES = %w[image/jpeg image/png image/webp].freeze
  INTAKE_PHOTO_MAX_SIZE = 10.megabytes

  # Lists crop every photo to the same box; the repair's page keeps the whole
  # photo and only shrinks it. Both drop the camera's metadata, which can weigh
  # more than a small thumbnail itself.
  THUMBNAIL_SIZE = [ 96, 72 ].freeze
  LARGE_SIZE = [ 960, 720 ].freeze

  belongs_to :bike
  belongs_to :mechanic, class_name: "Employee", foreign_key: :mechanic_id, optional: true

  has_many :payments, dependent: :restrict_with_error
  has_many :repair_line_items, dependent: :destroy
  has_many :services, through: :repair_line_items, dependent: :destroy

  # Destroying the repair deletes the attachment rows at once and purges the
  # files (and their blob rows) in a job. The rich text row goes with the repair.
  has_many_attached :intake_photos do |photo|
    photo.variant :thumbnail, resize_to_fill: THUMBNAIL_SIZE, saver: { strip: true, quality: 80 }
    photo.variant :large, resize_to_limit: LARGE_SIZE, saver: { strip: true, quality: 85 }
  end
  has_rich_text :diagnosis

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
  validate :intake_photos_are_images

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

  # Only the photos this save would add are checked; the ones on file passed
  # when they were uploaded.
  def intake_photos_are_images
    intake_photos.reject(&:persisted?).each do |photo|
      filename = photo.filename.to_s
      unless photo.content_type.in?(INTAKE_PHOTO_TYPES)
        errors.add(:intake_photos, :not_a_photo, filename: filename)
      end
      if photo.byte_size > INTAKE_PHOTO_MAX_SIZE
        errors.add(:intake_photos, :too_large, filename: filename,
          size: ActiveSupport::NumberHelper.number_to_human_size(photo.byte_size),
          limit: ActiveSupport::NumberHelper.number_to_human_size(INTAKE_PHOTO_MAX_SIZE))
      end
    end
  end

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
