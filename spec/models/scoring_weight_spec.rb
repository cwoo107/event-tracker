require "rails_helper"

RSpec.describe ScoringWeight, type: :model do
  it { is_expected.to validate_uniqueness_of(:criterion) }

  it "only accepts known criteria" do
    weight = build(:scoring_weight, criterion: "made_up")
    expect(weight).not_to be_valid
  end

  it "rejects weights outside 0-100" do
    expect(build(:scoring_weight, weight: 150)).not_to be_valid
    expect(build(:scoring_weight, weight: -5)).not_to be_valid
  end

  describe ".current" do
    it "returns zero for criteria without a stored row" do
      create(:scoring_weight, criterion: "drive_time", weight: 30)
      expect(ScoringWeight.current["weekend_weighting"]).to eq(0)
      expect(ScoringWeight.current["drive_time"]).to eq(30)
    end
  end
end
