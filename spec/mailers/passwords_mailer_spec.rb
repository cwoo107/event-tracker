require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    it "brands the email with an explicitly passed account" do
      account = create(:account, name: "Acme Org")
      user = create(:user, :admin, account: account)

      mail = described_class.reset(user, account: account)

      expect(mail["from"].value).to eq("Acme Org Event Tracker <notifications@usanmarketing.org>")
      expect(mail.html_part.body.to_s).to include("Acme Org account")
    end

    it "falls back to the user's first-joined account when none is given" do
      account = create(:account, name: "Fallback Org")
      user = create(:user, :admin, account: account)

      mail = described_class.reset(user)

      expect(mail["from"].value).to eq("Fallback Org Event Tracker <notifications@usanmarketing.org>")
    end

    it "degrades gracefully for a user with no account membership" do
      user = create(:user)

      mail = described_class.reset(user)

      expect(mail["from"].value).to eq("Event Tracker <notifications@usanmarketing.org>")
      expect(mail.html_part.body.to_s).to include("for your account")
    end
  end
end
