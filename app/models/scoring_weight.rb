class ScoringWeight < ApplicationRecord
  # The six percentage-weighted sliders on the Settings screen. Traffic is
  # intentionally not its own criterion - "drive_time" is traffic-adjusted
  # for the departure hour - and prep/teardown isn't scored at all, only
  # displayed. Boolean gates live in AssignmentRule, not here.
  CRITERIA = %w[
    drive_time
    weekly_load_balance
    weekend_weighting
    hours_of_day
    regional_familiarity
    back_to_back_travel
  ].freeze

  belongs_to :updated_by, class_name: "User", optional: true

  validates :criterion, presence: true, uniqueness: true, inclusion: { in: CRITERIA }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :ordered, -> { order(:criterion) }

  # Full set of current weights keyed by criterion, defaulting any
  # not-yet-configured criterion to 0 so the scoring engine never has to
  # special-case a missing row.
  def self.current
    CRITERIA.index_with { |criterion| find_by(criterion: criterion)&.weight || 0 }
  end
end
