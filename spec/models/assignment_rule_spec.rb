require "rails_helper"

RSpec.describe AssignmentRule, type: :model do
  it { is_expected.to validate_uniqueness_of(:key) }

  it "only accepts known keys" do
    rule = build(:assignment_rule, key: "made_up_rule")
    expect(rule).not_to be_valid
  end

  describe ".threshold_for" do
    it "returns the configured threshold for a key" do
      create(:assignment_rule, key: "no_consecutive_long_haul_miles", threshold: 150)
      expect(AssignmentRule.threshold_for("no_consecutive_long_haul_miles")).to eq(150)
    end

    it "returns nil for an unconfigured key" do
      expect(AssignmentRule.threshold_for("weekend_events_annual_cap")).to be_nil
    end
  end

  describe ".enabled" do
    it "scopes to rules currently toggled on" do
      on_rule = create(:assignment_rule, key: "max_weekly_events", enabled: true)
      create(:assignment_rule, key: "weekend_events_annual_cap", enabled: false)

      expect(AssignmentRule.enabled).to contain_exactly(on_rule)
    end
  end
end
