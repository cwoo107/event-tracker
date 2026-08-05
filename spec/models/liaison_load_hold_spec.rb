require "rails_helper"

RSpec.describe LiaisonLoadHold, type: :model do
  it { is_expected.to belong_to(:liaison) }

  it "requires at least one restriction" do
    hold = build(:liaison_load_hold, max_drive_minutes: nil, block_weekends: false)

    expect(hold).not_to be_valid
    expect(hold.errors[:base]).to include("must restrict weekends, drive time, or both")
  end

  describe "#blocks?" do
    it "blocks a weekend event when block_weekends is set" do
      hold = create(:liaison_load_hold, block_weekends: true, max_drive_minutes: nil)
      weekend_event = build(:event, :weekend)

      expect(hold.blocks?(weekend_event)).to be true
    end

    it "blocks an event whose drive time exceeds the cap" do
      hold = create(:liaison_load_hold, max_drive_minutes: 90, block_weekends: false)
      long_drive_event = build(:event, drive_time_seconds: 100.minutes.to_i)

      expect(hold.blocks?(long_drive_event)).to be true
    end

    it "does not block an event within the cap" do
      hold = create(:liaison_load_hold, max_drive_minutes: 90, block_weekends: false)
      short_drive_event = build(:event, drive_time_seconds: 30.minutes.to_i, starts_at: Time.zone.parse("2026-08-03 09:00"))

      expect(hold.blocks?(short_drive_event)).to be false
    end

    it "does not block once the hold has expired" do
      hold = create(:liaison_load_hold, block_weekends: true, ends_on: 1.day.ago.to_date)
      weekend_event = build(:event, :weekend)

      expect(hold.blocks?(weekend_event)).to be false
    end
  end
end
