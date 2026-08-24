require "net/http"
require "json"

module Geocoding
  # One-way drive distance/time/route between two points via Mapbox's
  # Directions API, under predicted traffic for the trip that would get
  # someone from origin to destination by a given arrival time - the same
  # account/token the map and the intake form's geocoder already use. A
  # real synchronous HTTP call: acceptable at this app's scale, but if
  # usage grows enough that a slow Mapbox response becomes a real problem,
  # this is the natural seam to move onto an ActiveJob instead -
  # Event#refresh_drive_time! already calls this as a self-contained step,
  # not inline logic a job would need to duplicate (it's actually already
  # backgrounded via RefreshDriveTimeJob).
  class DriveRoute
    PROFILE = "driving-traffic"
    BASE_URL = "https://api.mapbox.com/directions/v5/mapbox/#{PROFILE}"
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5

    # mapbox/driving-traffic has no "arrive by" option of its own - only
    # the non-traffic mapbox/driving profile does - so #solve approximates
    # one itself: ask for the traffic-aware duration of departing at a
    # candidate time, use that to refine the candidate, and repeat. Capped
    # so a pathological case (or a bug) can't loop forever; in practice a
    # couple of rounds is enough since traffic conditions change smoothly
    # through the day, even for a multi-hour drive where the conditions
    # near departure can look nothing like the conditions near arrival.
    MAX_ATTEMPTS = 4
    CONVERGED_WITHIN = 60 # seconds

    def initialize(origin:, destination:, arrive_by:, access_token: AppCredentials.mapbox_access_token)
      @origin = origin
      @destination = destination
      @arrive_by = arrive_by
      @access_token = access_token
    end

    def found?
      result.present?
    end

    def distance_meters
      result && result[:distance_meters]
    end

    def duration_seconds
      result && result[:duration_seconds]
    end

    # GeoJSON LineString geometry ({"type" => "LineString", "coordinates" => [[lng, lat], ...]})
    # for drawing the actual route on the map, straight from Mapbox - not
    # simplified or re-derived from distance/duration.
    def geometry
      result && result[:geometry]
    end

    # The clock time this trip would need to depart the office to arrive
    # by @arrive_by, given traffic conditions at that departure time - see
    # #solve, this isn't just @arrive_by minus a single duration lookup.
    def depart_at
      result && result[:depart_at]
    end

    private

    def result
      return @result if defined?(@result)

      @result = solve
    end

    def solve
      return nil if @access_token.blank? || @origin.nil? || @destination.nil? || @arrive_by.nil?

      depart_at = @arrive_by
      fetched = nil
      previous_duration = nil

      MAX_ATTEMPTS.times do |attempt|
        fetched = fetch(depart_at)
        return nil unless fetched

        break if previous_duration && (fetched[:duration_seconds] - previous_duration).abs <= CONVERGED_WITHIN
        break if attempt == MAX_ATTEMPTS - 1

        previous_duration = fetched[:duration_seconds]
        depart_at = @arrive_by - fetched[:duration_seconds].seconds
      end

      fetched&.merge(depart_at: depart_at)
    end

    # Fails closed, not loud - a network hiccup or a location Mapbox can't
    # route to shouldn't block saving the event. Callers see "not found"
    # exactly like they would if this were never called at all, matching
    # the "not yet calculated" state the UI already handles.
    def fetch(depart_at)
      uri = build_uri(depart_at)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      response = http.get(uri.request_uri)
      return nil unless response.code.to_i.between?(200, 299)

      route = JSON.parse(response.body)["routes"]&.first
      return nil unless route

      { distance_meters: route["distance"].round, duration_seconds: route["duration"].round, geometry: route["geometry"] }
    rescue JSON::ParserError, Timeout::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout,
           Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
      Rails.logger.warn("[Geocoding::DriveRoute] #{e.class}: #{e.message}")
      nil
    end

    def build_uri(depart_at)
      coordinates = "#{coord(@origin)};#{coord(@destination)}"
      query = URI.encode_www_form(
        access_token: @access_token,
        overview: "full",
        geometries: "geojson",
        depart_at: depart_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      )
      URI("#{BASE_URL}/#{coordinates}.json?#{query}")
    end

    def coord(point)
      lng = point.respond_to?(:x) ? point.x : point[0]
      lat = point.respond_to?(:y) ? point.y : point[1]
      "#{lng},#{lat}"
    end
  end
end
