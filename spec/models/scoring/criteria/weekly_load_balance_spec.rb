require "rails_helper"

RSpec.describe Scoring::Criteria::WeeklyLoadBalance, type: :model do
  let(:event) { create(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), ends_at: Time.zone.parse("2026-08-12 11:00")) } # Wed
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }

  def assign_event!(starts_at:)
    e = create(:event, starts_at: starts_at, ends_at: starts_at + 2.hours)
    e.assign_to!(liaison, by: admin)
  end

  it "scores 1.0 with no events yet this week" do
    criterion = described_class.new(event, liaison, weekly_target: 2)
    expect(criterion.score).to eq(1.0)
  end

  it "scores 0.5 with one event against a target of two" do
    assign_event!(starts_at: Time.zone.parse("2026-08-10 09:00")) # Monday, same week
    criterion = described_class.new(event, liaison, weekly_target: 2)
    expect(criterion.score).to eq(0.5)
  end

  it "scores 0.0 once already at the weekly target" do
    assign_event!(starts_at: Time.zone.parse("2026-08-10 09:00"))
    assign_event!(starts_at: Time.zone.parse("2026-08-11 09:00"))
    criterion = described_class.new(event, liaison, weekly_target: 2)
    expect(criterion.score).to eq(0.0)
  end

  it "ignores events in other weeks" do
    assign_event!(starts_at: Time.zone.parse("2026-08-03 09:00")) # the prior week
    criterion = described_class.new(event, liaison, weekly_target: 2)
    expect(criterion.score).to eq(1.0)
  end
end
