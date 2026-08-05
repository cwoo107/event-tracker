require "rails_helper"

RSpec.describe Scoring::Criteria::RegionalFamiliarity, type: :model do
  let(:liaison) { create(:liaison) }
  let(:admin) { create(:user, :admin) }

  it "scores 0 with no prior history" do
    event = create(:event, county: "Sacramento", requester_organization: "Yolo Farm Bureau")
    expect(described_class.new(event, liaison).score).to eq(0.0)
  end

  it "scores 0.6 for a prior event in the same county" do
    prior = create(:event, county: "Sacramento", requester_organization: "Some Other Org")
    prior.assign_to!(liaison, by: admin)
    event = create(:event, county: "Sacramento", requester_organization: "Yolo Farm Bureau")

    expect(described_class.new(event, liaison).score).to eq(0.6)
  end

  it "scores 1.0 for a prior event with the same requester organization" do
    prior = create(:event, county: "Nevada County", requester_organization: "Yolo Farm Bureau")
    prior.assign_to!(liaison, by: admin)
    event = create(:event, county: "Sacramento", requester_organization: "Yolo Farm Bureau")

    expect(described_class.new(event, liaison).score).to eq(1.0)
  end

  it "matches the organization case-insensitively" do
    prior = create(:event, requester_organization: "YOLO FARM BUREAU")
    prior.assign_to!(liaison, by: admin)
    event = create(:event, county: "Sacramento", requester_organization: "yolo farm bureau")

    expect(described_class.new(event, liaison).score).to eq(1.0)
  end
end
