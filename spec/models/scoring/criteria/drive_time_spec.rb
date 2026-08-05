require "rails_helper"

RSpec.describe Scoring::Criteria::DriveTime, type: :model do
  let(:event) { create(:event, starts_at: Time.zone.parse("2026-08-10 09:00"), ends_at: Time.zone.parse("2026-08-10 11:00")) }
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }

  def assign_past_event!(liaison, drive_time_seconds:, on:)
    past_event = create(:event,
      starts_at: Time.zone.local(on.year, on.month, on.day, 9),
      ends_at: Time.zone.local(on.year, on.month, on.day, 11),
      drive_time_seconds: drive_time_seconds)
    past_event.assign_to!(liaison, by: admin)
  end

  it "scores 1.0 with no drive-hour history" do
    criterion = described_class.new(event, liaison, team_average_hours: 20.0)
    expect(criterion.score).to eq(1.0)
  end

  it "scores 1.0 for any liaison when the team average is zero" do
    criterion = described_class.new(event, liaison, team_average_hours: 0.0)
    expect(criterion.score).to eq(1.0)
  end

  it "scores 0.5 at exactly the team average" do
    assign_past_event!(liaison, drive_time_seconds: 5 * 3600, on: Date.new(2026, 2, 1)) # 5h one-way -> 10 round-trip hrs
    criterion = described_class.new(event, liaison, team_average_hours: 10.0)
    expect(criterion.score).to eq(0.5)
  end

  it "scores 0.0 at double the team average or beyond" do
    assign_past_event!(liaison, drive_time_seconds: 10 * 3600, on: Date.new(2026, 2, 1)) # 20 round-trip hrs
    criterion = described_class.new(event, liaison, team_average_hours: 10.0)
    expect(criterion.score).to eq(0.0)
  end
end
