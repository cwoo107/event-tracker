require "rails_helper"

RSpec.describe Scoring::Rules::NoConsecutiveLongHaul, type: :model do
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }

  def miles(n)
    (n * 1609.344).round
  end

  def assign_event!(starts_at:, drive_distance_meters:)
    e = create(:event, starts_at: starts_at, ends_at: starts_at + 2.hours, drive_distance_meters: drive_distance_meters)
    e.assign_to!(liaison, by: admin)
  end

  it "has no violation when the rule isn't configured" do
    event = build(:event, drive_distance_meters: miles(200))
    expect(described_class.new(event, liaison, threshold_miles: nil).violation).to be_nil
  end

  it "has no violation when this event isn't long-haul" do
    event = build(:event, drive_distance_meters: miles(50))
    expect(described_class.new(event, liaison, threshold_miles: 150).violation).to be_nil
  end

  it "flags a violation when the liaison has an adjacent-day long-haul assignment" do
    assign_event!(starts_at: Time.zone.parse("2026-08-11 09:00"), drive_distance_meters: miles(200))
    event = build(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), drive_distance_meters: miles(200))

    violation = described_class.new(event, liaison, threshold_miles: 150).violation
    expect(violation).to include("another long-haul (150mi+) assignment")
  end
end
