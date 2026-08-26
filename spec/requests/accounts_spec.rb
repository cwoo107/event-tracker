require "rails_helper"

RSpec.describe "Accounts", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, :admin, account: account) }

  it "creates a new account, makes the current user its admin, and switches to it" do
    sign_in_as(user)

    expect {
      post accounts_path, params: { account: { name: "Second Org" } }
    }.to change(Account, :count).by(1)

    new_account = Account.find_by!(name: "Second Org")
    membership = AccountMembership.find_by(user: user, account: new_account)
    expect(membership).to be_admin
    expect(new_account.assignment_setting).to be_present
    expect(response).to redirect_to(root_path)
    expect(Session.order(created_at: :desc).first.account).to eq(new_account)
  end

  it "re-renders the form without creating anything on invalid input" do
    sign_in_as(user)
    account_count = Account.count

    post accounts_path, params: { account: { name: "" } }

    expect(Account.count).to eq(account_count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  describe "update" do
    it "lets an admin update the account's home office" do
      sign_in_as(user)

      patch account_path, params: {
        account: {
          office_address: "4005 Port Chicago Hwy", office_city: "Concord", office_state: "CA", office_zip: "94520",
          office_latitude: "38.0116", office_longitude: "-122.0247"
        }
      }

      expect(response).to redirect_to(account_users_path)
      expect(account.reload.office_city).to eq("Concord")
    end

    it "blocks a non-admin" do
      coordinator = create(:user)
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      sign_in_as(coordinator)

      patch account_path, params: { account: { office_city: "Hacked City" } }

      expect(response).to redirect_to(root_path)
      expect(account.reload.office_city).not_to eq("Hacked City")
    end
  end
end
