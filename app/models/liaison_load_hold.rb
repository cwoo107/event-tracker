class LiaisonLoadHold < ApplicationRecord
  belongs_to :liaison
  belongs_to :created_by, class_name: "User", optional: true

  validates :ends_on, presence: true
  validates :max_drive_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validate :at_least_one_restriction

  scope :active, -> { where("ends_on >= ?", Date.current) }

  # Would this hold block offering the liaison the given event? Used by the
  # (future) scoring engine before an event is ever scored for this liaison.
  def blocks?(event)
    return false unless active_on?(Date.current)

    (block_weekends? && event.weekend?) ||
      (max_drive_minutes.present? && event.drive_time_minutes.to_i > max_drive_minutes)
  end

  private

  def active_on?(date)
    ends_on >= date
  end

  def at_least_one_restriction
    return if block_weekends? || max_drive_minutes.present?

    errors.add(:base, "must restrict weekends, drive time, or both")
  end
end
