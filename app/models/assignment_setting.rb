class AssignmentSetting < ApplicationRecord
  belongs_to :account
  belongs_to :updated_by, class_name: "User", optional: true

  validates :work_weeks_per_year, :weekly_target, numericality: { only_integer: true, greater_than: 0 }
  validates :account_id, uniqueness: true

  # The whole app reads pacing through this one-per-account row rather
  # than a per-liaison column, matching the Settings screen's shared
  # "Calendar basis" panel (46 weeks x 2/week = 92, applied uniformly
  # across one account).
  def self.for(account)
    account.assignment_setting || account.create_assignment_setting!(work_weeks_per_year: 46, weekly_target: 2)
  end
end
