class RiskAssessment
  Result = Struct.new(:liaison, :level, :reasons, keyword_init: true) do
    def high?
      level == :high
    end

    def watch?
      level == :watch
    end

    def flagged?
      high? || watch?
    end
  end

  LEVELS = %i[high watch ok low].freeze

  # A liaison is flagged based on how many of three independent burnout
  # factors are currently triggered - over weekly pace, an elevated
  # weekend load, or an elevated cumulative drive burden (hours, YTD)
  # relative to the team average:
  #   high  - two or more factors triggered at once (compounding)
  #   watch - exactly one
  #   low   - meaningfully behind the team's average YTD event count
  #           (plenty of room, the opposite of at-risk) - a separate
  #           dimension from the three above, not just "zero triggered"
  #   ok    - everything else
  #
  # Drive burden is a genuinely separate factor from weekend load - a
  # liaison can carry a heavy cumulative drive burden while having a
  # perfectly normal weekend count, and the two shouldn't be conflated
  # into one signal. The multipliers below are configurable (Settings ->
  # "Burnout risk detection") via RiskThreshold, with the constants here
  # only used as an absolute fallback if that table is somehow empty and
  # RiskThreshold.active_multiplier can't resolve a default either.
  #
  # Deliberately simple and legible over statistically elaborate - this is
  # a flag meant to prompt a coordinator to look closer, not a verdict.
  FALLBACK_MULTIPLIER = 1.3

  def initialize(pool: Liaison.active, reference_date: Date.current)
    @pool = pool.to_a
    @reference_date = reference_date
  end

  def results
    @results ||= @pool.map { |liaison| assess(liaison) }
  end

  def for(liaison)
    results.find { |result| result.liaison == liaison }
  end

  def flagged
    results.select(&:flagged?)
  end

  def average_weekend_count
    @average_weekend_count ||= average(@pool.map { |liaison| liaison.weekend_events_ytd(reference_date: @reference_date) })
  end

  def average_ytd_count
    @average_ytd_count ||= average(@pool.map { |liaison| liaison.ytd_event_count(reference_date: @reference_date) })
  end

  def average_drive_hours
    @average_drive_hours ||= average(@pool.map { |liaison| liaison.ytd_drive_hours(reference_date: @reference_date) })
  end

  private

  def assess(liaison)
    reasons = []
    weekly_count = liaison.events_in_week(@reference_date).count
    weekend_count = liaison.weekend_events_ytd(reference_date: @reference_date)
    ytd_count = liaison.ytd_event_count(reference_date: @reference_date)
    drive_hours = liaison.ytd_drive_hours(reference_date: @reference_date)

    over_pace = weekly_count > weekly_target
    high_weekend = exceeds?(weekend_count, average_weekend_count, weekend_multiplier)
    high_drive_burden = exceeds?(drive_hours, average_drive_hours, drive_multiplier)
    behind_pace = pace_multiplier && average_ytd_count.positive? && ytd_count < average_ytd_count * pace_multiplier

    reasons << "#{weekly_count} events this week (guideline #{weekly_target})" if over_pace
    if high_weekend
      reasons << "#{weekend_count} weekend events YTD vs a #{average_weekend_count.round(1)} team average"
    end
    if high_drive_burden
      reasons << "#{drive_hours.round} drive hours YTD vs a #{average_drive_hours.round(1)} team average"
    end

    triggered_count = [over_pace, high_weekend, high_drive_burden].count(true)

    level =
      if triggered_count >= 2
        :high
      elsif triggered_count == 1
        :watch
      elsif behind_pace
        :low
      else
        :ok
      end

    Result.new(liaison: liaison, level: level, reasons: reasons)
  end

  # A factor only fires if it has a live multiplier (nil means switched
  # off entirely, see RiskThreshold.active_multiplier) and there's a real,
  # positive team average to compare against.
  def exceeds?(value, team_average, multiplier)
    multiplier && team_average.positive? && value > team_average * multiplier
  end

  def weekly_target
    @weekly_target ||= AssignmentSetting.current.weekly_target
  end

  def weekend_multiplier
    @weekend_multiplier ||= RiskThreshold.active_multiplier("weekend_load_multiplier")
  end

  def drive_multiplier
    @drive_multiplier ||= RiskThreshold.active_multiplier("drive_burden_multiplier")
  end

  def pace_multiplier
    @pace_multiplier ||= RiskThreshold.active_multiplier("behind_pace_multiplier")
  end

  def average(values)
    return 0.0 if values.empty?

    values.sum.to_f / values.size
  end
end
