class RepairOrder < ApplicationRecord
  belongs_to :bike
  belongs_to :mechanic, optional: true
  has_many :repair_line_items, -> { oldest_first }, dependent: :destroy
  has_many :services, through: :repair_line_items

  has_rich_text :diagnosis

  INTAKE_PHOTO_TYPES = %w[ image/jpeg image/png image/webp image/heic image/heif ].freeze
  INTAKE_PHOTO_MAX_SIZE = 10.megabytes

  # Purge synchronously so no Active Storage row outlives the repair.
  before_destroy :purge_intake_photos, prepend: true

  has_many_attached :intake_photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 160, 120 ]
    attachable.variant :large, resize_to_limit: [ 800, 600 ]
  end

  accepts_nested_attributes_for :repair_line_items,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs["service_id"].blank? }

  enum :status, {
    dropped_off: "Dropped Off",
    awaiting_estimate_approval: "Awaiting Estimate Approval",
    in_progress: "In Progress",
    ready_for_pickup: "Ready for Pickup",
    picked_up: "Picked Up"
  }

  validates :status, presence: true
  validates :promised_on, presence: true

  validate :intake_photos_are_acceptable
  validate :dates_are_not_before_intake
  validate :lifecycle_consistency

  scope :by_promised_date, -> { order(:promised_on) }
  scope :open, -> { where.not(status: :picked_up) }
  scope :overdue, -> { open.where("promised_on < ?", Date.current) }

  def overdue?
    !picked_up? && promised_on < Date.current
  end

  def status_label
    self.class.statuses[status]
  end

  def total
    repair_line_items.sum(:charged_price)
  end

  # Assigning photos adds to the ones already stored; assigning none changes nothing.
  # (Rails 8 would otherwise replace them all, or delete them all for a blank field.)
  def intake_photos=(attachables)
    attachables = Array(attachables).compact_blank
    super(intake_photos.blobs.to_a + attachables) if attachables.any?
  end

  # Photos already stored, ignoring any attachment still waiting to be saved.
  def stored_intake_photos
    intake_photos_attachments.select(&:persisted?)
  end

  def diagnosis_preview(length = 80)
    diagnosis.to_plain_text.squish.truncate(length)
  end

  private

  def purge_intake_photos
    intake_photos.each(&:purge)
  end

  def intake_photos_are_acceptable
    intake_photos.each do |photo|
      next if photo.blob.persisted?

      unless INTAKE_PHOTO_TYPES.include?(photo.blob.content_type)
        errors.add(:intake_photos, "\"#{photo.filename}\" is not an accepted image (use JPEG, PNG, WebP or HEIC)")
      end

      if photo.blob.byte_size > INTAKE_PHOTO_MAX_SIZE
        errors.add(:intake_photos, "\"#{photo.filename}\" is larger than #{ActiveSupport::NumberHelper.number_to_human_size(INTAKE_PHOTO_MAX_SIZE)}")
      end
    end
  end

  def intake_date
    (created_at || Time.current).to_date
  end

  def dates_are_not_before_intake
    if picked_up_at.present? && picked_up_at.to_date < intake_date
      errors.add(:picked_up_at, "can't be before the day the bike came in")
    end

    if promised_on.present? && promised_on < intake_date
      errors.add(:promised_on, "can't be before the day the bike came in")
    end
  end

  def lifecycle_consistency
    if picked_up_at.present? && !picked_up?
      errors.add(:picked_up_at, "can't be set before the repair has been picked up")
    end

    if !dropped_off? && !awaiting_estimate_approval? && quote_accepted.nil?
      errors.add(:quote_accepted, "must be recorded before the repair moves past the estimate")
    end
  end
end
