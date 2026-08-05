class DashboardReport
  LiaisonRow = Struct.new(:liaison, :ytd_count, :annual_target, :weekly_count, :weekend_count,
                           :drive_hours, :miles, :risk, keyword_init: true)

  RANGES = %w[fy quarter last30].freeze

  def initialize(range: "fy", reference_date: Date.current, pool: Liaison.active)
    @range = RANGES.include?(range) ? range : "fy"
    @reference_date = reference_date
    @pool = pool.includes(:user).to_a
  end

  def range
    @range
  end

  def range_label
    { "fy" => "FY #{@reference_date.year}", "quarter" => "Q#{(@reference_date.month / 3.0).ceil}",
      "last30" => "Last 30 days" }.fetch(@range)
  end

  def since
    case @range
    when "quarter" then quarter_start
    when "last30" then @reference_date - 30.days
    else year_start
    end
  end

  def open_requests_count
    Event.unassigned.count
  end

  def assigned_this_week_count
    Event.in_week_of(@reference_date).assigned.count
  end

  def total_this_week_count
    Event.in_week_of(@reference_date).count
  end

  def average_drive_minutes
    seconds = Event.counted_toward_load.where(starts_at: since..@reference_date)
                   .where.not(drive_time_seconds: nil).pluck(:drive_time_seconds)
    return 0 if seconds.empty?

    (seconds.sum / seconds.size / 60.0).round
  end

  def weekend_event_count
    Event.counted_toward_load.weekend.where(starts_at: since..@reference_date).count
  end

  def risk_assessment
    @risk_assessment ||= RiskAssessment.new(pool: @pool, reference_date: @reference_date)
  end

  # Sorted highest-YTD-count first, matching the mockup's per-liaison table.
  def liaison_rows
    @liaison_rows ||= @pool.map do |liaison|
      LiaisonRow.new(
        liaison: liaison,
        ytd_count: liaison.event_count(since..@reference_date),
        annual_target: liaison.annual_target(@reference_date.year),
        weekly_count: liaison.events_in_week(@reference_date).count,
        weekend_count: liaison.weekend_count(since..@reference_date),
        drive_hours: liaison.drive_hours(since..@reference_date).round,
        miles: liaison.miles(since..@reference_date).round,
        risk: risk_assessment.for(liaison)
      )
    end.sort_by { |row| -row.ytd_count }
  end

  # One point per week for the trailing `weeks` weeks - the org-wide
  # equivalent of a single liaison's weekly_pacing_history.
  def weekly_pacing_series(weeks: 12)
    target = @pool.size * AssignmentSetting.current.weekly_target

    Array.new(weeks) do |i|
      week_start = @reference_date.to_date.beginning_of_week - (weeks - 1 - i).weeks
      count = Event.in_week_of(week_start).counted_toward_load.count
      { week_start: week_start, count: count, over_target: count > target }
    end
  end

  # Simplified against the original mockup's per-county breakdown: grouped
  # by each liaison's own home region rather than mapping every event's
  # county to a region (that mapping doesn't exist in the schema), so this
  # reads as "how much load is each region's liaison carrying" rather than
  # "where did events in this region actually happen."
  #
  # Superseded by #events_by_region below - liaisons aren't currently
  # being assigned regions, so grouping by Liaison#region would mostly
  # bucket everyone into "Unmapped." Left in place (unused by the
  # dashboard view) rather than deleted, since re-enabling region
  # assignment later would make this meaningful again without needing to
  # be rebuilt.
  def geographic_coverage
    liaison_rows.group_by { |row| row.liaison.region }
                .sort_by { |region, _| region.to_s }
  end

  # Where events are actually happening, via RegionLookup rather than
  # Liaison#region - answers a different question than the method above,
  # and works regardless of whether liaisons have regions on file.
  def events_by_region
    Event.where(starts_at: since..@reference_date).where.not(status: :cancelled)
         .group_by { |event| RegionLookup.for(event) || "Unmapped" }
         .transform_values(&:count)
         .sort_by { |_, count| -count }
  end

  def upcoming_events(limit: 8)
    Event.upcoming.in_next_days(30).includes(:liaisons).order(:starts_at).limit(limit)
  end

  def burnout_watch
    risk_assessment.flagged
  end

  private

  def year_start
    Date.new(@reference_date.year, 1, 1)
  end

  def quarter_start
    quarter = ((@reference_date.month - 1) / 3) + 1
    Date.new(@reference_date.year, ((quarter - 1) * 3) + 1, 1)
  end
end
