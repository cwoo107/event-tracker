require "rails_helper"

RSpec.describe Assignment, type: :model do
  it { is_expected.to belong_to(:event) }
  it { is_expected.to belong_to(:liaison) }
  it { is_expected.to belong_to(:assigned_by).class_name("User").optional }

  it "defaults to the manual assignment method" do
    assignment = create(:assignment)
    expect(assignment).to be_assignment_method_manual
  end

  it "defaults to accepted and active" do
    assignment = create(:assignment)
    expect(assignment).to be_assignment_status_accepted
    expect(assignment).to be_active
  end

  describe ".active" do
    it "scopes to assignments not yet superseded" do
      current = create(:assignment, active: true)
      superseded = create(:assignment, active: false)

      expect(Assignment.active).to contain_exactly(current)
      expect(Assignment.active).not_to include(superseded)
    end
  end

  describe ".recent_first" do
    it "orders by created_at descending" do
      older = create(:assignment, created_at: 2.days.ago)
      newer = create(:assignment, created_at: 1.hour.ago)

      expect(Assignment.recent_first).to eq([newer, older])
    end
  end
end
