require "rails_helper"

RSpec.describe Scoring::Criteria::WeekendWeighting, type: :model do
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }

  def assign_event!(starts_at:)
    e = create(:event, starts_at: starts_at, ends_at: starts_at + 2.hours)
    e.assign_to!(liaison, by: admin)
  end

  describe "for a weekday event" do
    let(:event) { create(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), ends_at: Time.zone.parse("2026-08-12 11:00")) }

    it "is neutral regardless of weekend history" do
      criterion = described_class.new(event, liaison, team_average_weekend_load: 5.0)
      expect(criterion.score).to eq(0.5)
    end
  end

  describe "for a weekend event" do
    let(:event) { create(:event, starts_at: Time.zone.parse("2026-08-15 09:00"), ends_at: Time.zone.parse("2026-08-15 11:00")) } # Sat

    it "scores 1.0 with no weekend history" do
      criterion = described_class.new(event, liaison, team_average_weekend_load: 3.0)
      expect(criterion.score).to eq(1.0)
    end

    it "scores 0.5 at the team average, applying the 1.5x weekend multiplier" do
      assign_event!(starts_at: Time.zone.parse("2026-02-07 09:00")) # a Saturday -> weighted 1.5
      criterion = described_class.new(event, liaison, team_average_weekend_load: 1.5)
      expect(criterion.score).to eq(0.5)
    end

    it "scores 1.0 for any liaison when the team average is zero" do
      criterion = described_class.new(event, liaison, team_average_weekend_load: 0.0)
      expect(criterion.score).to eq(1.0)
    end
  end
end
