require "rails_helper"

RSpec.describe Scoring::Rules::WeekendAnnualCap, type: :model do
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }
  let(:event) { create(:event, starts_at: Time.zone.parse("2026-08-15 09:00"), ends_at: Time.zone.parse("2026-08-15 11:00")) } # Sat

  def assign_weekend_event!(starts_at:)
    e = create(:event, starts_at: starts_at, ends_at: starts_at + 2.hours)
    e.assign_to!(liaison, by: admin)
  end

  it "has no violation when the rule isn't configured" do
    expect(described_class.new(event, liaison, threshold: nil).violation).to be_nil
  end

  it "has no violation for a weekday event, regardless of threshold" do
    weekday_event = create(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), ends_at: Time.zone.parse("2026-08-12 11:00"))
    expect(described_class.new(weekday_event, liaison, threshold: 0).violation).to be_nil
  end

  it "flags a violation once this weekend event would exceed the annual cap" do
    assign_weekend_event!(starts_at: Time.zone.parse("2026-02-07 09:00")) # a prior Saturday this year

    violation = described_class.new(event, liaison, threshold: 1).violation
    expect(violation).to eq("would be the liaison's 2nd weekend event this year (cap 1)")
  end
end
