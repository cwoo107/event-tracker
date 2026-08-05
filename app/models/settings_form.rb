class SettingsForm
  include ActiveModel::Model

  DEFAULT_WEIGHTS = {
    "drive_time" => 30,
    "weekly_load_balance" => 22,
    "weekend_weighting" => 18,
    "hours_of_day" => 12,
    "regional_familiarity" => 10,
    "back_to_back_travel" => 8
  }.freeze

  DEFAULT_RULES = {
    "max_weekly_events" => { threshold: 3, enabled: true },
    "overnight_required_over_hours" => { threshold: 3, enabled: true },
    "no_consecutive_long_haul_miles" => { threshold: 150, enabled: true },
    "earliest_departure_minutes" => { threshold: 360, enabled: true },
    "latest_return_minutes" => { threshold: 1260, enabled: true },
    "weekend_events_annual_cap" => { threshold: 12, enabled: false },
    "co_staffing_attendee_threshold" => { threshold: 500, enabled: true }
  }.freeze

  DEFAULT_WORK_WEEKS_PER_YEAR = 46
  DEFAULT_WEEKLY_TARGET = 2

  attr_accessor :weights, :rules, :risk_thresholds, :work_weeks_per_year, :weekly_target

  # Current state, for rendering the edit form - zero-filled for any
  # criterion/rule that's never been saved, rather than requiring the
  # database to already be seeded.
  def self.load
    new(
      weights: ScoringWeight::CRITERIA.index_with { |criterion| ScoringWeight.find_by(criterion: criterion)&.weight || 0 },
      rules: AssignmentRule::KEYS.keys.index_with { |key| AssignmentRule.find_by(key: key) },
      risk_thresholds: RiskThreshold::DEFAULTS.keys.index_with { |key| RiskThreshold.find_by(key: key) },
      work_weeks_per_year: AssignmentSetting.current.work_weeks_per_year,
      weekly_target: AssignmentSetting.current.weekly_target
    )
  end

  def self.reset_to_defaults!(updated_by: nil)
    ActiveRecord::Base.transaction do
      DEFAULT_WEIGHTS.each do |criterion, weight|
        ScoringWeight.find_or_initialize_by(criterion: criterion).update!(weight: weight, updated_by: updated_by)
      end
      DEFAULT_RULES.each do |key, attrs|
        AssignmentRule.find_or_initialize_by(key: key)
                      .update!(threshold: attrs[:threshold], enabled: attrs[:enabled], updated_by: updated_by)
      end
      RiskThreshold::DEFAULTS.each do |key, multiplier|
        RiskThreshold.find_or_initialize_by(key: key).update!(multiplier: multiplier, enabled: true, updated_by: updated_by)
      end
      AssignmentSetting.current.update!(
        work_weeks_per_year: DEFAULT_WORK_WEEKS_PER_YEAR,
        weekly_target: DEFAULT_WEEKLY_TARGET,
        updated_by: updated_by
      )
    end
  end

  # Saves the four tables as one transaction. Hard-rule thresholds aren't
  # edited through this form (only enabled/disabled, matching the Settings
  # screen's checklist) - a rule newly toggled on for the first time gets
  # seeded with its default threshold rather than a null one. Risk
  # thresholds *are* directly editable (that's the whole point of
  # exposing them here), so a newly-toggled-on one just uses whatever
  # multiplier was submitted alongside it.
  def save(params, updated_by: nil)
    ActiveRecord::Base.transaction do
      (params[:weights] || {}).each do |criterion, weight|
        ScoringWeight.find_or_initialize_by(criterion: criterion).update!(weight: weight, updated_by: updated_by)
      end

      AssignmentRule::KEYS.keys.each do |key|
        enabled_param = params.dig(:rules, key, :enabled)
        next if enabled_param.nil?

        rule = AssignmentRule.find_or_initialize_by(key: key) do |new_rule|
          new_rule.threshold = DEFAULT_RULES.dig(key, :threshold)
        end
        rule.enabled = ActiveModel::Type::Boolean.new.cast(enabled_param)
        rule.updated_by = updated_by
        rule.save!
      end

      RiskThreshold::DEFAULTS.keys.each do |key|
        enabled_param = params.dig(:risk_thresholds, key, :enabled)
        next if enabled_param.nil?

        threshold = RiskThreshold.find_or_initialize_by(key: key)
        threshold.enabled = ActiveModel::Type::Boolean.new.cast(enabled_param)
        threshold.multiplier = params.dig(:risk_thresholds, key, :multiplier).presence || RiskThreshold::DEFAULTS.fetch(key)
        threshold.updated_by = updated_by
        threshold.save!
      end

      AssignmentSetting.current.update!(
        work_weeks_per_year: params[:work_weeks_per_year],
        weekly_target: params[:weekly_target],
        updated_by: updated_by
      )
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end
end
