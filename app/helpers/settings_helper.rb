module SettingsHelper
  CRITERION_DESCRIPTIONS = {
    "drive_time" => "Minutes each way, traffic-adjusted for the departure hour",
    "weekly_load_balance" => "Distance from the weekly pacing guideline",
    "weekend_weighting" => "A weekend event counts extra toward the weekly load",
    "hours_of_day" => "Penalty for calls starting very early or ending late",
    "regional_familiarity" => "Prior events with the same requester or county",
    "back_to_back_travel" => "Penalty for consecutive long-haul days"
  }.freeze

  def criterion_description(criterion)
    CRITERION_DESCRIPTIONS.fetch(criterion, "")
  end

  # Mirrors the Settings mockup's checklist wording, but with the actual
  # stored threshold interpolated in rather than a static string, so it
  # can't drift out of sync with what the rule really enforces.
  def rule_description(key, rule)
    threshold = rule&.threshold || SettingsForm::DEFAULT_RULES.dig(key, :threshold)

    case key
    when "max_weekly_events"
      "Never schedule a liaison for more than #{threshold.to_i} events in a single week."
    when "overnight_required_over_hours"
      "Block same-day round trips over #{threshold.to_i} hours each way - require an approved overnight."
    when "no_consecutive_long_haul_miles"
      "No two long-haul (#{threshold.to_i} mi+) assignments on consecutive days."
    when "earliest_departure_minutes"
      "Earliest departure from the office #{format_minutes(threshold)}."
    when "latest_return_minutes"
      "Latest return to the office #{format_minutes(threshold)}."
    when "weekend_events_annual_cap"
      "Cap weekend events at #{threshold.to_i} per liaison per year."
    when "co_staffing_attendee_threshold"
      "Events over #{threshold.to_i} expected attendees require two liaisons."
    end
  end

  private

  def format_minutes(minutes)
    format("%02d:%02d", minutes.to_i / 60, minutes.to_i % 60)
  end
end
