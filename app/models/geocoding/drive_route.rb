require "net/http"
require "json"

module Geocoding
  # One-way drive distance/time between two points via Mapbox's Directions
  # API - the same account/token the map and the intake form's geocoder
  # already use. A real synchronous HTTP call: acceptable at this app's
  # scale, but if usage grows enough that a slow Mapbox response becomes a
  # real problem for someone submitting the intake form, this is the
  # natural seam to move onto an ActiveJob instead - Event#refresh_drive_time!
  # already calls this as a self-contained step, not inline logic a job
  # would need to duplicate.
  class DriveRoute
    BASE_URL = "https://api.mapbox.com/directions/v5/mapbox/driving"
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5

    def initialize(origin:, destination:, access_token: Rails.application.credentials.dig(:mapbox, :access_token))
      @origin = origin
      @destination = destination
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

    private

    def result
      return @result if defined?(@result)

      @result = fetch
    end

    # Fails closed, not loud - a network hiccup or a location Mapbox can't
    # route to shouldn't block saving the event. Callers see "not found"
    # exactly like they would if this were never called at all, matching
    # the "not yet calculated" state the UI already handles.
    def fetch
      return nil if @access_token.blank? || @origin.nil? || @destination.nil?

      uri = build_uri
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      response = http.get(uri.request_uri)
      return nil unless response.code.to_i.between?(200, 299)

      route = JSON.parse(response.body)["routes"]&.first
      return nil unless route

      { distance_meters: route["distance"].round, duration_seconds: route["duration"].round }
    rescue JSON::ParserError, Timeout::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout,
           Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
      Rails.logger.warn("[Geocoding::DriveRoute] #{e.class}: #{e.message}")
      nil
    end

    def build_uri
      coordinates = "#{coord(@origin)};#{coord(@destination)}"
      URI("#{BASE_URL}/#{coordinates}.json?access_token=#{@access_token}&overview=false")
    end

    def coord(point)
      lng = point.respond_to?(:x) ? point.x : point[0]
      lat = point.respond_to?(:y) ? point.y : point[1]
      "#{lng},#{lat}"
    end
  end
end
