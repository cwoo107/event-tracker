require "rails_helper"

RSpec.describe Geocoding::DriveRoute, type: :model do
  let(:origin) { RGeo::Geographic.spherical_factory(srid: 4326).point(-122.0247, 38.0116) }
  let(:destination) { RGeo::Geographic.spherical_factory(srid: 4326).point(-121.4944, 38.5816) }
  let(:arrive_by) { Time.zone.parse("2026-09-01 09:00") }

  def response_for(duration:)
    body = {
      routes: [ {
        distance: 123_456.7,
        duration: duration,
        geometry: { type: "LineString", coordinates: [ [ -122.0247, 38.0116 ], [ -121.4944, 38.5816 ] ] }
      } ]
    }.to_json
    instance_double(Net::HTTPResponse, code: "200", body: body)
  end

  def stub_http_get(*responses)
    http = instance_double(Net::HTTP)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:get).with(a_string_matching(/depart_at=/)).and_return(*responses)
    allow(Net::HTTP).to receive(:new).and_return(http)
  end

  describe "with a successful response" do
    it "converges on a departure time and exposes distance, duration, and geometry from that request" do
      # 1st guess (depart_at = arrive_by) comes back at 3600s; refined
      # guess (depart_at = arrive_by - 3600s) comes back at 3660s, close
      # enough (<= 60s) to stop refining.
      stub_http_get(response_for(duration: 3600), response_for(duration: 3660))

      route = described_class.new(origin: origin, destination: destination, arrive_by: arrive_by)

      expect(route).to be_found
      expect(route.distance_meters).to eq(123_457)
      expect(route.duration_seconds).to eq(3660)
      expect(route.depart_at).to eq(arrive_by - 3600.seconds)
      expect(route.geometry).to eq("type" => "LineString", "coordinates" => [ [ -122.0247, 38.0116 ], [ -121.4944, 38.5816 ] ])
    end

    it "stops after MAX_ATTEMPTS requests even without converging" do
      stub_http_get(*[ 3600, 4200, 4800, 5400 ].map { |d| response_for(duration: d) })

      route = described_class.new(origin: origin, destination: destination, arrive_by: arrive_by)

      expect(route).to be_found
      expect(route.duration_seconds).to eq(5400)
    end
  end

  describe "with no routes in the response" do
    before do
      response = instance_double(Net::HTTPResponse, code: "200", body: { routes: [] }.to_json)
      stub_http_get(response)
    end

    it "is not found and exposes nothing" do
      route = described_class.new(origin: origin, destination: destination, arrive_by: arrive_by)

      expect(route).not_to be_found
      expect(route.distance_meters).to be_nil
      expect(route.duration_seconds).to be_nil
      expect(route.geometry).to be_nil
      expect(route.depart_at).to be_nil
    end
  end

  describe "without an access token" do
    it "fails closed without making a request" do
      expect(Net::HTTP).not_to receive(:new)

      route = described_class.new(origin: origin, destination: destination, arrive_by: arrive_by, access_token: nil)

      expect(route).not_to be_found
      expect(route.geometry).to be_nil
    end
  end

  describe "without an arrival time" do
    it "fails closed without making a request" do
      expect(Net::HTTP).not_to receive(:new)

      route = described_class.new(origin: origin, destination: destination, arrive_by: nil, access_token: "token")

      expect(route).not_to be_found
    end
  end
end
