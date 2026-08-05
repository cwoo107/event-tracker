class Liaison < ApplicationRecord
  include Activatable
  include Initialing

  # Fixed coverage-area taxonomy shown on the Liaisons screen and used to
  # score "regional familiarity". A liaison's home region, not a hard
  # boundary on which events they can be offered.
  REGIONS = [
    "East Bay/Delta",
    "Sacramento Valley",
    "North Coast",
    "Far North",
    "South Bay/Peninsula",
    "Central Valley",
    "Sierra/Foothills",
    "Nevada"
  ].freeze

  belongs_to :user
  # update_only: true - without it, Rails' nested-attributes machinery
  # only updates the existing associated record when the submitted
  # attributes include its id; with neither an id field in the form nor
  # this option, every update built a brand new User instead of updating
  # the real one (hence "password can't be blank" / "email already
  # taken" on what should have been a plain profile edit). For a
  # belongs_to like this, there's only ever at most one possible User to
  # update - no id needed to disambiguate, so always update in place.
  accepts_nested_attributes_for :user, update_only: true

  has_many :liaison_time_offs, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :active_assignments, -> { where(active: true) }, class_name: "Assignment", inverse_of: :liaison
  has_many :events, through: :assignments # full history, including reassigned-away events
  has_many :current_events, through: :active_assignments, source: :event
  has_many :liaison_load_holds, dependent: :destroy

  validates :color, presence: true, uniqueness: true,
            format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a hex color like #1F8A4C" }
  validates :region, inclusion: { in: REGIONS }, allow_blank: true
  validate :user_has_liaison_role

  delegate :email_address, :name, to: :user
  alias_method :display_name, :name

  # A hard delete would cascade through dependent: :destroy on assignments
  # (see LiaisonsController#destroy), wiping out real historical records -
  # anyone who's actually been assigned something should be deactivated,
  # not destroyed.
  def destroyable?
    assignments.none?
  end

  # Comma-separated form input for the `skills` array column - keeps the
  # form from needing to know it's talking to a Postgres array, same idea
  # as Event's latitude=/longitude= writers for the geocoder.
  def skills_text
    skills.join(", ")
  end

  def skills_text=(value)
    self.skills = value.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  # Whole weeks of approved time off overlapping the given calendar year,
  # rounded to the nearest week so a single day off doesn't zero out a week
  # of capacity.
  def vacation_weeks(year = Date.current.year)
    (vacation_days(year) / 7.0).round
  end

  def available_weeks(year = Date.current.year)
    [AssignmentSetting.current.work_weeks_per_year - vacation_weeks(year), 0].max
  end

  def annual_target(year = Date.current.year)
    AssignmentSetting.current.weekly_target * available_weeks(year)
  end

  def active_load_hold
    liaison_load_holds.where("ends_on >= ?", Date.current).order(:ends_on).first
  end

  # --- Scoring-engine support -------------------------------------------
  # Shared queries used by more than one Scoring::Criteria/Rules class, so
  # each stays focused on its own math rather than repeating joins.

  def events_in_week(date)
    active_assignments.joins(:event).merge(Event.in_week_of(date))
  end

  # Generic range-based aggregates - the YTD-flavored methods below are
  # thin wrappers over these, and DashboardReport uses these directly to
  # support its FY/quarter/last-30-days toggle without duplicating the
  # underlying queries for each window.
  def event_count(range)
    active_assignments.joins(:event).merge(Event.counted_toward_load.where(starts_at: range)).count
  end

  def drive_hours(range)
    active_assignments.joins(:event).merge(Event.counted_toward_load.where(starts_at: range))
                       .sum("COALESCE(events.drive_time_seconds, 0) * 2") / 3600.0
  end

  def miles(range)
    active_assignments.joins(:event).merge(Event.counted_toward_load.where(starts_at: range))
                       .sum("COALESCE(events.drive_distance_meters, 0) * 2") / 1609.344
  end

  def weekend_count(range)
    active_assignments.joins(:event).merge(Event.counted_toward_load.where(starts_at: range)).merge(Event.weekend).count
  end

  # Round-trip drive hours accumulated this calendar year through
  # reference_date, feeding the "drive time" criterion's team-average
  # comparison.
  def ytd_drive_hours(reference_date: Date.current)
    drive_hours(year_range(reference_date))
  end

  def miles_ytd(reference_date: Date.current)
    miles(year_range(reference_date))
  end

  def ytd_event_count(reference_date: Date.current)
    event_count(year_range(reference_date))
  end

  # Plain count of weekend events YTD - callers apply their own weighting
  # (e.g. the "weekend weighting" criterion's 1.5x) rather than baking one
  # multiplier in here, since the hard annual-cap rule wants a plain count.
  def weekend_events_ytd(reference_date: Date.current)
    weekend_count(year_range(reference_date))
  end

  # One entry per week for the last `weeks` weeks (inclusive of the current
  # one), oldest first - feeds the liaison profile's "load history" bar
  # chart and (via DashboardReport's org-wide equivalent) the dashboard's
  # weekly pacing chart. Same shape as DashboardReport#weekly_pacing_series
  # so both can share one chart-data helper.
  def weekly_pacing_history(weeks: 12, reference_date: Date.current)
    target = AssignmentSetting.current.weekly_target

    Array.new(weeks) do |i|
      week_start = reference_date.to_date.beginning_of_week - (weeks - 1 - i).weeks
      count = events_in_week(week_start).count
      { week_start: week_start, count: count, over_target: count > target }
    end
  end

  def upcoming_events(limit: 8, reference_date: Date.current)
    current_events.where("starts_at >= ?", reference_date.beginning_of_day).order(:starts_at).limit(limit)
  end

  # The liaison's long-haul (>= threshold_miles) assignment on the given
  # date, if any - used to detect back-to-back long-distance travel.
  def long_haul_assignment_on(date, threshold_miles)
    active_assignments.joins(:event).includes(:event)
                       .merge(Event.where(starts_at: date.beginning_of_day..date.end_of_day))
                       .detect { |assignment| (assignment.event.drive_distance_miles || 0) >= threshold_miles.to_f }
  end

  private

  def year_range(reference_date)
    Date.new(reference_date.year, 1, 1).beginning_of_day..reference_date.end_of_day
  end

  def vacation_days(year)
    year_start = Date.new(year, 1, 1)
    year_end = Date.new(year, 12, 31)

    liaison_time_offs.sum do |time_off|
      overlap_start = [time_off.starts_on, year_start].max
      overlap_end = [time_off.ends_on, year_end].min
      overlap_end >= overlap_start ? (overlap_end - overlap_start + 1).to_i : 0
    end
  end

  def user_has_liaison_role
    errors.add(:user, "must have the liaison role") if user && !user.liaison?
  end
end
