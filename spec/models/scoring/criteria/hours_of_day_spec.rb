require "rails_helper"

RSpec.describe Scoring::Criteria::HoursOfDay, type: :model do
  it "scores 1.0 for a mid-day event with no drive time recorded" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), ends_at: Time.zone.parse("2026-08-12 11:00"),
                           prep_minutes: 30, teardown_minutes: 30, drive_time_seconds: nil)
    expect(described_class.new(event).score).to eq(1.0)
  end

  it "penalizes an implied departure before 06:00" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 06:15"), ends_at: Time.zone.parse("2026-08-12 08:00"),
                           prep_minutes: 30, teardown_minutes: 15, drive_time_seconds: nil)
    # prep_starts_at = 05:45
    expect(described_class.new(event).score).to eq(0.5)
  end

  it "penalizes an implied return after 19:00" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 17:00"), ends_at: Time.zone.parse("2026-08-12 18:45"),
                           prep_minutes: 15, teardown_minutes: 30, drive_time_seconds: nil)
    # teardown_ends_at = 19:15
    expect(described_class.new(event).score).to eq(0.5)
  end

  it "stacks both penalties, and factors in drive time, for an event that's both early and late" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 05:50"), ends_at: Time.zone.parse("2026-08-12 19:10"),
                           prep_minutes: 30, teardown_minutes: 30, drive_time_seconds: 30.minutes.to_i)
    expect(described_class.new(event).score).to eq(0.0)
  end
end
