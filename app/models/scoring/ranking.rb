module Scoring
  # Ranks active liaisons against an unassigned event: one weighted score
  # per ScoringWeight criterion, plus any AssignmentRule/LiaisonLoadHold
  # violations, surfaced separately so the ranked-list UI can show *why* a
  # candidate scored the way it did (score breakdown bars) and *why* it's
  # blocked, if it is (the manual-override warning).
  #
  # Usage:
  #   ranking = Scoring::Ranking.new(event)
  #   ranking.candidates   # every active liaison, best first, blocked last
  #   ranking.eligible      # candidates with no rule/hold violations
  #   ranking.best          # the top eligible candidate, or nil
  #
  # Note on scale: this issues a handful of small queries per liaison
  # (weekly count, YTD hours, prior events, adjacent-day check). Fine for
  # the roster size in the mockups (~8 liaisons); would want batch-loading
  # if the team grew substantially.
  class Ranking
    CRITERIA = {
      "drive_time" => Criteria::DriveTime,
      "weekly_load_balance" => Criteria::WeeklyLoadBalance,
      "weekend_weighting" => Criteria::WeekendWeighting,
      "hours_of_day" => Criteria::HoursOfDay,
      "regional_familiarity" => Criteria::RegionalFamiliarity,
      "back_to_back_travel" => Criteria::BackToBackTravel
    }.freeze

    SIMPLE_RULES = {
      "max_weekly_events" => Rules::MaxWeeklyEvents,
      "overnight_required_over_hours" => Rules::OvernightApproval,
      "no_consecutive_long_haul_miles" => Rules::NoConsecutiveLongHaul,
      "weekend_events_annual_cap" => Rules::WeekendAnnualCap
    }.freeze

    def initialize(event, pool: nil)
      @event = event
      @pool = (pool || event.account.liaisons.active).to_a
    end

    def candidates
      @candidates ||= @pool.map { |liaison| build_candidate(liaison) }
                            .sort_by { |c| [c.blocked? ? 1 : 0, -c.score] }
    end

    def eligible
      candidates.reject(&:blocked?)
    end

    def best
      eligible.first
    end

    private

    def build_candidate(liaison)
      breakdown = {}
      weighted_sum = 0.0
      weight_sum = 0.0

      CRITERIA.each do |key, criterion_class|
        weight = weights[key].to_f
        next if weight <= 0

        goodness = criterion_class.new(@event, liaison, **criterion_args(key)).score
        breakdown[key] = (weight * goodness).round(2)
        weighted_sum += weight * goodness
        weight_sum += weight
      end

      score = weight_sum.zero? ? 0.0 : (100.0 * weighted_sum / weight_sum).round(2)

      Scoring::Candidate.new(liaison: liaison, score: score, breakdown: breakdown, block_reasons: violations_for(liaison))
    end

    def criterion_args(key)
      case key
      when "drive_time" then { team_average_hours: team_average_drive_hours }
      when "weekly_load_balance" then { weekly_target: AssignmentSetting.for(@event.account).weekly_target }
      when "weekend_weighting" then { team_average_weekend_load: team_average_weekend_load }
      when "back_to_back_travel" then { long_haul_threshold_miles: long_haul_threshold_miles }
      else {}
      end
    end

    def violations_for(liaison)
      reasons = []

      hold = liaison.active_load_hold
      reasons << "load hold active until #{hold.ends_on.strftime('%b %-d')}" if hold&.blocks?(@event)

      SIMPLE_RULES.each do |key, rule_class|
        rule = enabled_rules[key]
        next unless rule

        violation = rule_class.new(@event, liaison, **rule_kwargs(key, rule.threshold)).violation
        reasons << violation if violation
      end

      departure_rule = enabled_rules["earliest_departure_minutes"]
      return_rule = enabled_rules["latest_return_minutes"]
      if departure_rule || return_rule
        violation = Rules::DepartureReturnWindow.new(
          @event, liaison,
          earliest_departure_minutes: departure_rule&.threshold,
          latest_return_minutes: return_rule&.threshold
        ).violation
        reasons << violation if violation
      end

      reasons
    end

    # Each rule class names its threshold kwarg for what it actually
    # measures (hours, miles, a plain count) rather than a generic
    # `threshold:` everywhere, so this maps AssignmentRule's stored value
    # onto the right keyword per rule.
    def rule_kwargs(key, threshold)
      case key
      when "max_weekly_events", "weekend_events_annual_cap"
        { threshold: threshold }
      when "overnight_required_over_hours"
        { threshold_hours: threshold }
      when "no_consecutive_long_haul_miles"
        { threshold_miles: threshold }
      end
    end

    def weights
      @weights ||= @event.account.scoring_weights.current
    end

    def enabled_rules
      @enabled_rules ||= @event.account.assignment_rules.enabled.index_by(&:key)
    end

    def long_haul_threshold_miles
      @long_haul_threshold_miles ||= @event.account.assignment_rules.threshold_for("no_consecutive_long_haul_miles") || 150
    end

    def team_average_drive_hours
      @team_average_drive_hours ||= average(@pool.map { |l| l.ytd_drive_hours(reference_date: @event.starts_at.to_date) })
    end

    def team_average_weekend_load
      @team_average_weekend_load ||= average(
        @pool.map { |l| l.weekend_events_ytd(reference_date: @event.starts_at.to_date) * Criteria::WeekendWeighting::WEEKEND_MULTIPLIER }
      )
    end

    def average(values)
      return 0.0 if values.empty?

      values.sum.to_f / values.size
    end
  end
end
