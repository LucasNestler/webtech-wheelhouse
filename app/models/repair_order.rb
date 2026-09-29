class RepairOrder < ApplicationRecord
  belongs_to :bike
  belongs_to :mechanic, optional: true
  has_many :repair_line_items, -> { oldest_first }, dependent: :destroy
  has_many :services, through: :repair_line_items

  enum :status, {
    dropped_off: "Dropped Off",
    awaiting_estimate_approval: "Awaiting Estimate Approval",
    in_progress: "In Progress",
    ready_for_pickup: "Ready for Pickup",
    picked_up: "Picked Up"
  }

  validates :status, presence: true
  validates :promised_on, presence: true

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

  private

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
