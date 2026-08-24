require "rails_helper"

RSpec.describe AssignmentSetting, type: :model do
  describe ".for" do
    it "creates a default row for an account that has none" do
      account = create(:account)

      expect { AssignmentSetting.for(account) }.to change(AssignmentSetting, :count).by(1)
      expect(AssignmentSetting.for(account).work_weeks_per_year).to eq(46)
      expect(AssignmentSetting.for(account).weekly_target).to eq(2)
    end

    it "reuses the existing row rather than creating another" do
      account = create(:account)
      existing = create(:assignment_setting, account: account, weekly_target: 3)

      expect(AssignmentSetting.for(account)).to eq(existing)
    end

    it "scopes lookups to the given account" do
      account_a = create(:account)
      account_b = create(:account)
      setting_a = create(:assignment_setting, account: account_a, weekly_target: 3)

      expect(AssignmentSetting.for(account_a)).to eq(setting_a)
      expect(AssignmentSetting.for(account_b)).not_to eq(setting_a)
    end
  end

  describe "validations" do
    it "refuses a second row for the same account" do
      account = create(:account)
      create(:assignment_setting, account: account)
      second = build(:assignment_setting, account: account)

      expect(second).not_to be_valid
      expect(second.errors[:account_id]).to be_present
    end

    it "allows one row per account" do
      second = build(:assignment_setting, account: create(:account))

      expect(second).to be_valid
    end
  end
end
