class AssignmentSetting < ApplicationRecord
  belongs_to :updated_by, class_name: "User", optional: true

  validates :work_weeks_per_year, :weekly_target, numericality: { only_integer: true, greater_than: 0 }
  validate :only_one_row_exists, on: :create

  # The whole app reads pacing through this single row rather than a
  # per-liaison column, matching the Settings screen's shared "Calendar
  # basis" panel (46 weeks x 2/week = 92, applied uniformly).
  def self.current
    first || create!(work_weeks_per_year: 46, weekly_target: 2)
  end

  private

  def only_one_row_exists
    errors.add(:base, "assignment settings already exist - update the existing row") if AssignmentSetting.exists?
  end
end
