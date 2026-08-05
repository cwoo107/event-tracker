require "rails_helper"

RSpec.describe Liaison, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:color) }
    it { is_expected.to validate_uniqueness_of(:color) }

    it "requires the underlying user to have the liaison role" do
      coordinator = create(:user, role: :coordinator)
      liaison = build(:liaison, user: coordinator)

      expect(liaison).not_to be_valid
      expect(liaison.errors[:user]).to include("must have the liaison role")
    end

    it "rejects malformed colors" do
      liaison = build(:liaison, color: "green")
      expect(liaison).not_to be_valid
    end

    it "requires a region from the fixed list" do
      liaison = build(:liaison, region: "Tahoe")
      expect(liaison).not_to be_valid
    end
  end

  describe "#available_weeks" do
    it "returns the org's full work-week calendar when there is no time off" do
      create(:assignment_setting, work_weeks_per_year: 46, weekly_target: 2)
      liaison = create(:liaison)

      expect(liaison.available_weeks(2026)).to eq(46)
    end

    it "subtracts full weeks of time off from the calendar" do
      create(:assignment_setting, work_weeks_per_year: 46, weekly_target: 2)
      liaison = create(:liaison)
      create(:liaison_time_off, liaison: liaison, starts_on: Date.new(2026, 7, 1), ends_on: Date.new(2026, 7, 14))

      expect(liaison.available_weeks(2026)).to eq(44)
    end
  end

  describe "#annual_target" do
    it "is the org-wide weekly target multiplied by available weeks" do
      create(:assignment_setting, work_weeks_per_year: 46, weekly_target: 2)
      liaison = create(:liaison)

      expect(liaison.annual_target(2026)).to eq(92)
    end

    it "drops as vacation time increases, uniformly for every liaison" do
      create(:assignment_setting, work_weeks_per_year: 46, weekly_target: 2)
      liaison = create(:liaison)
      create(:liaison_time_off, liaison: liaison, starts_on: Date.new(2026, 8, 1), ends_on: Date.new(2026, 8, 21))

      expect(liaison.annual_target(2026)).to eq(86)
    end
  end
end
