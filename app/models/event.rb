class Event < ApplicationRecord
  # How early a liaison is expected to arrive relative to the event's
  # start time - the arrival target Geocoding::DriveRoute solves backward
  # from when computing traffic-aware drive time/distance/route (see
  # #refresh_drive_time!). Independent of prep_minutes, which is about
  # setup time once already on site, not travel planning.
  DRIVE_ARRIVAL_BUFFER = 30.minutes

  enum :status, { unassigned: 0, assigned: 1, completed: 2, cancelled: 3 }, default: :unassigned
  enum :source, { public_form: 0, member_portal: 1, manual: 2 }, default: :manual

  belongs_to :account
  # Account-managed catalog (see EventType) - admins add/rename/retire
  # entries from the account settings screen, replacing what used to be
  # a fixed enum shared by every account.
  belongs_to :event_type

  # No liaison_id here: an event's current liaison(s) are its active
  # assignments. Almost always exactly one, but the co-staffing hard rule
  # (500+ attendees requires two) means it can't be a single FK.
  has_many :assignments, dependent: :destroy
  has_many :active_assignments, -> { where(active: true) }, class_name: "Assignment", inverse_of: :event
  has_many :liaisons, through: :active_assignments
  has_many :event_material_items, dependent: :destroy
  has_many :material_items, through: :event_material_items
  has_many :notes, dependent: :destroy
  has_many :activities, as: :subject, dependent: :destroy

  validates :title, :starts_at, :ends_at, :location, presence: true
  validates :prep_minutes, :teardown_minutes, numericality: { greater_than_or_equal_to: 0 }
  validate :ends_at_after_starts_at
  before_validation :build_location_from_coordinates

  # Virtual attributes for the intake form's geocoded coordinates (see the
  # #latitude/#longitude readers below, which derive from `location` once
  # it's built - these writers only exist to build it in the first place).
  attr_writer :latitude, :longitude

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :in_next_days, ->(days) { where(starts_at: Time.current..days.days.from_now) }
  scope :weekend, -> { where("EXTRACT(ISODOW FROM starts_at) IN (6, 7)") }
  scope :near, ->(point, meters) do
    where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)", point.x, point.y, meters)
  end
  scope :in_week_of, ->(date) do
    week_start = date.to_date.beginning_of_week
    where(starts_at: week_start.beginning_of_day..(week_start + 6.days).end_of_day)
  end
  # events that should count toward a liaison's load/pacing figures -
  # excludes unassigned (not yet committed) and cancelled events
  scope :counted_toward_load, -> { where(status: [:assigned, :completed]) }

  def duration_minutes
    ((ends_at - starts_at) / 60).round
  end

  def prep_starts_at
    starts_at - prep_minutes.minutes
  end

  def teardown_ends_at
    ends_at + teardown_minutes.minutes
  end

  # The full on-site commitment, prep through teardown - what a liaison's
  # day actually looks like, not just the advertised event window.
  def on_site_window
    prep_starts_at..teardown_ends_at
  end

  def weekend?
    starts_at.saturday? || starts_at.sunday?
  end

  def start_hour
    starts_at.hour
  end

  def latitude
    location&.y
  end

  def longitude
    location&.x
  end

  def drive_time_minutes
    drive_time_seconds && (drive_time_seconds / 60.0).round
  end

  def drive_distance_miles
    drive_distance_meters && (drive_distance_meters / 1609.344).round(1)
  end

  # Plain Google Maps driving-directions link for the reminder email - a
  # liaison needs turn-by-turn directions in their pocket on the day of,
  # not the Mapbox route geometry the map view draws (see DriveRoute).
  # Origin is the account's office when it's set, so the link opens
  # already routed from HQ; Google Maps falls back to the visitor's
  # current location when origin is omitted.
  def google_maps_directions_url
    return unless latitude && longitude

    params = { api: 1, destination: "#{latitude},#{longitude}", travelmode: "driving" }
    params[:origin] = "#{account.office_latitude},#{account.office_longitude}" if account.office_location

    "https://www.google.com/maps/dir/?#{params.to_query}"
  end

  # Calls Mapbox for the one-way drive route from the account's home
  # office (Account#office_location, set on the Settings screen) to this
  # event's location under predicted traffic for arriving
  # DRIVE_ARRIVAL_BUFFER before starts_at, and persists the result,
  # including the route geometry so the map can draw the actual driving
  # line without calling Mapbox again on every view. Deliberately not an
  # after_save callback - it's enqueued via RefreshDriveTimeJob after a
  # successful create, or an update that changed the location (see
  # EventsController), so every other way an Event gets created
  # (factories, specs, db/seeds/historical_events.rb) stays fast and
  # offline, and doesn't need Mapbox stubbed to run. Silently leaves
  # drive_distance_meters/drive_time_seconds/drive_route_geometry
  # unchanged if Mapbox can't be reached or has nothing useful to say -
  # see Geocoding::DriveRoute - or if the account hasn't set an office
  # location yet.
  def refresh_drive_time!
    return unless location && starts_at && account.office_location

    route = Geocoding::DriveRoute.new(
      origin: account.office_location, destination: location, arrive_by: starts_at - DRIVE_ARRIVAL_BUFFER
    )
    return unless route.found?

    update_columns(
      drive_distance_meters: route.distance_meters,
      drive_time_seconds: route.duration_seconds,
      drive_route_geometry: route.geometry
    )
  end

  # When a liaison would actually need to leave/get back, accounting for
  # the drive from the office. Used by the "hours of day" scoring criterion
  # and the earliest-departure/latest-return hard rule. Doesn't handle a
  # drive that would push past midnight - a v1 simplification, noted rather
  # than silently wrong for the rare case it'd matter.
  def implied_departure_time
    prep_starts_at - (drive_time_minutes || 0).minutes
  end

  def implied_return_time
    teardown_ends_at + (drive_time_minutes || 0).minutes
  end

  def reference_code
    "EV-#{1000 + id}"
  end

  # Advisory helpers reflecting the co-staffing hard rule - enforcement
  # belongs to the scoring engine, these just expose the current state.
  def requires_second_liaison?
    estimated_attendees.to_i > (account.assignment_rules.threshold_for("co_staffing_attendee_threshold") || 500)
  end

  def co_staffed?
    liaisons.count > 1
  end

  def fully_staffed?
    liaisons.any? && (!requires_second_liaison? || co_staffed?)
  end

  # Adds a liaison to the event's active assignment set (a second call adds
  # a co-liaison rather than replacing the first - use reassign_to! for the
  # common "swap the one liaison" case).
  def assign_to!(liaison, by:, assignment_method: :manual, score: nil, score_breakdown: {})
    transaction do
      assignment = assignments.create!(
        liaison: liaison, assigned_by: by, assignment_method: assignment_method,
        score: score, score_breakdown: score_breakdown, active: true
      )
      update!(status: :assigned)
      activities.create!(
        actor: by, action: "assigned",
        meta: { liaison_id: liaison.id, assignment_method: assignment_method.to_s }
      )
      assignment
    end
  end

  # Deactivates one liaison's assignment, or all of them if none is given.
  def unassign!(by:, liaison: nil)
    transaction do
      scope = assignments.where(active: true)
      scope = scope.where(liaison: liaison) if liaison
      scope.find_each { |assignment| assignment.update!(active: false) }

      update!(status: :unassigned) if assignments.where(active: true).none?
      activities.create!(actor: by, action: "unassigned", meta: liaison ? { liaison_id: liaison.id } : {})
    end
  end

  # The common single-liaison "Reassign" action from the event card:
  # replaces every currently active liaison with a new one, atomically.
  def reassign_to!(new_liaison, by:, assignment_method: :manual, score: nil, score_breakdown: {})
    transaction do
      liaisons.to_a.each { |current| unassign!(by: by, liaison: current) }
      assign_to!(new_liaison, by: by, assignment_method: assignment_method, score: score, score_breakdown: score_breakdown)
    end
  end

  def complete!(by:)
    update!(status: :completed)
    activities.create!(actor: by, action: "completed")
  end

  private

  def build_location_from_coordinates
    return if @latitude.blank? || @longitude.blank?

    self.location = RGeo::Geographic.spherical_factory(srid: 4326).point(@longitude.to_f, @latitude.to_f)
  end

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after the start time") if ends_at <= starts_at
  end
end
