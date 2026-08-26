require "rails_helper"

RSpec.describe Account, type: :model do
  describe "office location" do
    it "builds office_location from the submitted latitude/longitude" do
      account = create(:account, office_latitude: 38.0116, office_longitude: -122.0247)

      expect(account.office_location.y).to eq(38.0116)
      expect(account.office_location.x).to eq(-122.0247)
    end

    it "leaves office_location unset without coordinates" do
      account = create(:account, office_latitude: nil, office_longitude: nil)

      expect(account.office_location).to be_nil
    end
  end

  describe "#seed_defaults!" do
    it "seeds settings, the material catalog, and event types without touching another account" do
      account = create(:account)
      other_account = create(:account)
      other_account.seed_defaults!
      other_account.scoring_weights.find_by(criterion: "drive_time").update!(weight: 99)

      account.seed_defaults!

      expect(account.assignment_setting).to be_present
      expect(account.scoring_weights.find_by(criterion: "drive_time").weight).to eq(30)
      expect(account.material_items.pluck(:name)).to match_array(MaterialItem::DEFAULT_CATALOG)
      expect(account.event_types.pluck(:name)).to match_array(EventType::DEFAULT_CATALOG)
      expect(other_account.scoring_weights.find_by(criterion: "drive_time").weight).to eq(99)
    end
  end

  describe "destroying an account" do
    it "clears sessions pinned to it and memberships, but leaves the user's login intact" do
      account = create(:account)
      user = create(:user, :admin, account: account)
      session = user.sessions.create!(account: account)

      account.destroy

      expect { session.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(User.exists?(user.id)).to be true
      expect(user.account_memberships.where(account: account)).to be_empty
    end
  end
end
