require "rails_helper"

RSpec.describe Scoring::Ranking, type: :model do
  let(:admin) { create(:user, :admin) }
  let(:event) { create(:event, starts_at: Time.zone.parse("2026-08-12 09:00"), ends_at: Time.zone.parse("2026-08-12 11:00")) } # Wed

  def assign_event!(liaison, starts_at:)
    e = create(:event, starts_at: starts_at, ends_at: starts_at + 2.hours)
    e.assign_to!(liaison, by: admin)
  end

  before do
    create(:assignment_setting, work_weeks_per_year: 46, weekly_target: 2)
  end

  describe "weighting and ranking" do
    before do
      # only one criterion weighted, so this spec is deterministic and
      # isolated to the thing under test rather than all six at once
      create(:scoring_weight, criterion: "weekly_load_balance", weight: 100)
    end

    it "ranks liaisons with more room this week above those closer to pace" do
      fresh = create(:liaison)
      busy = create(:liaison)
      assign_event!(busy, starts_at: Time.zone.parse("2026-08-10 09:00"))
      assign_event!(busy, starts_at: Time.zone.parse("2026-08-11 09:00"))

      ranking = described_class.new(event, pool: Liaison.where(id: [fresh.id, busy.id]))

      expect(ranking.candidates.map(&:liaison)).to eq([fresh, busy])
      expect(ranking.candidates.first.score).to eq(100.0)
      expect(ranking.candidates.last.score).to eq(0.0)
    end

    it "includes only the configured criterion in the breakdown" do
      liaison = create(:liaison)
      ranking = described_class.new(event, pool: Liaison.where(id: liaison.id))

      expect(ranking.candidates.first.breakdown.keys).to eq(["weekly_load_balance"])
    end
  end

  describe "hard-rule blocking" do
    before do
      create(:scoring_weight, criterion: "weekly_load_balance", weight: 100)
      create(:assignment_rule, key: "max_weekly_events", threshold: 1, enabled: true)
    end

    it "marks a liaison blocked once this event would exceed the hard cap, but still scores them" do
      liaison = create(:liaison)
      assign_event!(liaison, starts_at: Time.zone.parse("2026-08-10 09:00")) # already at the cap of 1

      ranking = described_class.new(event, pool: Liaison.where(id: liaison.id))
      candidate = ranking.candidates.first

      expect(candidate).to be_blocked
      expect(candidate.block_reasons.first).to include("limit 1")
      expect(ranking.eligible).to be_empty
      expect(ranking.best).to be_nil
    end

    it "sorts blocked candidates after eligible ones regardless of score" do
      blocked_liaison = create(:liaison)
      assign_event!(blocked_liaison, starts_at: Time.zone.parse("2026-08-10 09:00"))
      eligible_liaison = create(:liaison)

      ranking = described_class.new(event, pool: Liaison.where(id: [blocked_liaison.id, eligible_liaison.id]))

      expect(ranking.candidates.map(&:liaison)).to eq([eligible_liaison, blocked_liaison])
      expect(ranking.best.liaison).to eq(eligible_liaison)
    end
  end

  describe "load holds" do
    before do
      create(:scoring_weight, criterion: "weekly_load_balance", weight: 100)
    end

    it "blocks a liaison whose active load hold covers this event" do
      liaison = create(:liaison)
      weekend_event = create(:event, :weekend)
      create(:liaison_load_hold, liaison: liaison, block_weekends: true, max_drive_minutes: nil,
                                  ends_on: 1.month.from_now.to_date)

      ranking = described_class.new(weekend_event, pool: Liaison.where(id: liaison.id))
      candidate = ranking.candidates.first

      expect(candidate).to be_blocked
      expect(candidate.block_reasons.first).to include("load hold active")
    end
  end
end
