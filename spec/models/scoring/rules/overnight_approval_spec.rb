require "rails_helper"

RSpec.describe Scoring::Rules::OvernightApproval, type: :model do
  let(:liaison) { create(:liaison) }

  it "has no violation when the rule isn't configured" do
    event = build(:event, drive_time_seconds: 4.hours.to_i)
    expect(described_class.new(event, liaison, threshold_hours: nil).violation).to be_nil
  end

  it "has no violation under the threshold" do
    event = build(:event, drive_time_seconds: 2.hours.to_i)
    expect(described_class.new(event, liaison, threshold_hours: 3).violation).to be_nil
  end

  it "has no violation over the threshold once the overnight is approved" do
    event = build(:event, drive_time_seconds: 4.hours.to_i, overnight_approved: true)
    expect(described_class.new(event, liaison, threshold_hours: 3).violation).to be_nil
  end

  it "flags a violation over the threshold without an approved overnight" do
    event = build(:event, drive_time_seconds: 4.hours.to_i, overnight_approved: false)
    violation = described_class.new(event, liaison, threshold_hours: 3).violation

    expect(violation).to include("exceeds the 3.0h same-day threshold")
  end
end
