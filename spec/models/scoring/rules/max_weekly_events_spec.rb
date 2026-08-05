require "rails_helper"

RSpec.describe Scoring::Rules::MaxWeeklyEvents, type: :model do
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }
  let(:event) { create(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), ends_at: Time.zone.parse("2026-08-12 11:00")) }

  def assign_event!(starts_at:)
    e = create(:event, starts_at: starts_at, ends_at: starts_at + 2.hours)
    e.assign_to!(liaison, by: admin)
  end

  it "has no violation when the rule isn't configured" do
    expect(described_class.new(event, liaison, threshold: nil).violation).to be_nil
  end

  it "has no violation under the threshold" do
    expect(described_class.new(event, liaison, threshold: 3).violation).to be_nil
  end

  it "flags a violation once this event would exceed the threshold" do
    assign_event!(starts_at: Time.zone.parse("2026-08-10 09:00"))
    assign_event!(starts_at: Time.zone.parse("2026-08-11 09:00"))

    violation = described_class.new(event, liaison, threshold: 2).violation
    expect(violation).to eq("would be the liaison's 3rd event this week (limit 2)")
  end
end
