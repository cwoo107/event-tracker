class AssignmentRule < ApplicationRecord
  # Mirrors the Settings screen's "Hard rules" checklist. These are gates
  # the (future) scoring engine must satisfy before offering a liaison at
  # all, as opposed to ScoringWeight's percentage-weighted criteria.
  # `threshold` units differ by key - documented here rather than in a
  # separate column, since each rule has exactly one meaningful unit:
  KEYS = {
    "max_weekly_events" => "events per week",
    "overnight_required_over_hours" => "one-way drive hours before an approved overnight is required",
    "no_consecutive_long_haul_miles" => "one-way miles considered long-haul, disallowed on consecutive days",
    "earliest_departure_minutes" => "minutes since midnight for the earliest allowed departure",
    "latest_return_minutes" => "minutes since midnight for the latest allowed return",
    "weekend_events_annual_cap" => "weekend events per liaison per year",
    "co_staffing_attendee_threshold" => "expected attendees above which two liaisons are required"
  }.freeze

  belongs_to :account
  belongs_to :updated_by, class_name: "User", optional: true

  validates :key, presence: true, uniqueness: { scope: :account_id }, inclusion: { in: KEYS.keys }

  scope :enabled, -> { where(enabled: true) }

  def self.threshold_for(key)
    find_by(key: key)&.threshold
  end
end
