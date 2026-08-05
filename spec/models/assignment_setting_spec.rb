require "rails_helper"

RSpec.describe AssignmentSetting, type: :model do
  describe ".current" do
    it "creates a default row when none exists" do
      expect { AssignmentSetting.current }.to change(AssignmentSetting, :count).by(1)
      expect(AssignmentSetting.current.work_weeks_per_year).to eq(46)
      expect(AssignmentSetting.current.weekly_target).to eq(2)
    end

    it "reuses the existing row rather than creating another" do
      existing = create(:assignment_setting, weekly_target: 3)
      expect(AssignmentSetting.current).to eq(existing)
    end
  end

  describe "validations" do
    it "refuses to create a second row" do
      create(:assignment_setting)
      second = build(:assignment_setting)

      expect(second).not_to be_valid
      expect(second.errors[:base]).to be_present
    end
  end
end
