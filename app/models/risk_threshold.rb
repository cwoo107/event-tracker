class RiskThreshold < ApplicationRecord
  DEFAULTS = {
    "weekend_load_multiplier" => 1.3,
    "drive_burden_multiplier" => 1.3,
    "behind_pace_multiplier" => 0.75
  }.freeze

  KEY_DESCRIPTIONS = {
    "weekend_load_multiplier" => "How far above the team's average YTD weekend load counts as elevated",
    "drive_burden_multiplier" => "How far above the team's average YTD drive hours counts as elevated",
    "behind_pace_multiplier" => "How far below the team's average YTD event count counts as meaningfully behind (and therefore low risk, not at-risk)"
  }.freeze

  belongs_to :updated_by, class_name: "User", optional: true

  validates :key, presence: true, uniqueness: true, inclusion: { in: DEFAULTS.keys }
  validates :multiplier, numericality: { greater_than: 0 }

  scope :enabled, -> { where(enabled: true) }

  # nil means "this factor is switched off - never trigger it," distinct
  # from "not yet configured" (which uses DEFAULTS). RiskAssessment treats
  # a nil multiplier as a reason to skip that check entirely rather than
  # falling back to some default ratio.
  def self.active_multiplier(key)
    rule = find_by(key: key)
    return nil if rule && !rule.enabled?

    rule&.multiplier || DEFAULTS.fetch(key)
  end
end
