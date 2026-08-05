require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email_address) }

  it "downcases and strips the email address" do
    user = create(:user, email_address: "  Caleb@USANMarketing.example ")
    expect(user.email_address).to eq("caleb@usanmarketing.example")
  end

  describe "#short_name" do
    it "abbreviates to first name plus last initial" do
      user = build(:user, name: "Caleb Bennett")
      expect(user.short_name).to eq("Caleb B.")
    end

    it "handles a single-word name gracefully" do
      user = build(:user, name: "Caleb")
      expect(user.short_name).to eq("Caleb")
    end
  end
end
