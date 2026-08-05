require "rails_helper"

RSpec.describe Scoring::Rules::DepartureReturnWindow, type: :model do
  let(:liaison) { create(:liaison) }

  it "has no violation when neither bound is configured" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 05:00"), ends_at: Time.zone.parse("2026-08-12 20:00"),
                           drive_time_seconds: nil)
    violation = described_class.new(event, liaison, earliest_departure_minutes: nil, latest_return_minutes: nil).violation
    expect(violation).to be_nil
  end

  it "flags an early departure against the configured bound" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 05:00"), ends_at: Time.zone.parse("2026-08-12 09:00"),
                           prep_minutes: 30, drive_time_seconds: nil)
    violation = described_class.new(event, liaison, earliest_departure_minutes: 360, latest_return_minutes: nil).violation

    expect(violation).to eq("would depart before the 06:00 earliest-departure rule")
  end

  it "flags a late return against the configured bound" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 17:00"), ends_at: Time.zone.parse("2026-08-12 21:00"),
                           teardown_minutes: 30, drive_time_seconds: nil)
    violation = described_class.new(event, liaison, earliest_departure_minutes: nil, latest_return_minutes: 1260).violation

    expect(violation).to eq("would return after the 21:00 latest-return rule")
  end

  it "flags both when the event violates both bounds" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 05:00"), ends_at: Time.zone.parse("2026-08-12 21:30"),
                           prep_minutes: 30, teardown_minutes: 30, drive_time_seconds: nil)
    violation = described_class.new(event, liaison, earliest_departure_minutes: 360, latest_return_minutes: 1260).violation

    expect(violation).to include("earliest-departure")
    expect(violation).to include("latest-return")
  end
end
