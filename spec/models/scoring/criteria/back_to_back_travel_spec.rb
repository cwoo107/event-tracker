require "rails_helper"

RSpec.describe Scoring::Criteria::BackToBackTravel, type: :model do
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }

  def miles(n)
    (n * 1609.344).round
  end

  def assign_event!(starts_at:, drive_distance_meters:)
    e = create(:event, starts_at: starts_at, ends_at: starts_at + 2.hours, drive_distance_meters: drive_distance_meters)
    e.assign_to!(liaison, by: admin)
  end

  it "scores 1.0 when this event isn't long-haul" do
    event = build(:event, drive_distance_meters: miles(100))
    criterion = described_class.new(event, liaison, long_haul_threshold_miles: 150)
    expect(criterion.score).to eq(1.0)
  end

  it "scores 1.0 for a long-haul event with no adjacent long-haul assignment" do
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), drive_distance_meters: miles(200))
    criterion = described_class.new(event, liaison, long_haul_threshold_miles: 150)
    expect(criterion.score).to eq(1.0)
  end

  it "scores 0.0 when the liaison already has a long-haul assignment the day before" do
    assign_event!(starts_at: Time.zone.parse("2026-08-11 09:00"), drive_distance_meters: miles(200))
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), drive_distance_meters: miles(200))

    criterion = described_class.new(event, liaison, long_haul_threshold_miles: 150)
    expect(criterion.score).to eq(0.0)
  end

  it "scores 0.0 when the liaison already has a long-haul assignment the day after" do
    assign_event!(starts_at: Time.zone.parse("2026-08-13 09:00"), drive_distance_meters: miles(200))
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), drive_distance_meters: miles(200))

    criterion = described_class.new(event, liaison, long_haul_threshold_miles: 150)
    expect(criterion.score).to eq(0.0)
  end
end
