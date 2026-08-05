require "rails_helper"

RSpec.describe LiaisonTimeOff, type: :model do
  it { is_expected.to belong_to(:liaison) }

  it "is invalid when ends_on precedes starts_on" do
    time_off = build(:liaison_time_off, starts_on: Date.new(2026, 8, 10), ends_on: Date.new(2026, 8, 1))

    expect(time_off).not_to be_valid
    expect(time_off.errors[:ends_on]).to include("must be on or after the start date")
  end

  describe ".covering" do
    it "returns time off spanning a given date" do
      liaison = create(:liaison)
      covering = create(:liaison_time_off, liaison: liaison, starts_on: Date.new(2026, 8, 1), ends_on: Date.new(2026, 8, 10))
      create(:liaison_time_off, liaison: liaison, starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 10))

      expect(LiaisonTimeOff.covering(Date.new(2026, 8, 5))).to contain_exactly(covering)
    end
  end
end
