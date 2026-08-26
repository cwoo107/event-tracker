require "rails_helper"

RSpec.describe "Account users", type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :admin, account: account) }

  def membership_path_for(user, in_account = account)
    account_user_path(AccountMembership.find_by(user: user, account: in_account))
  end

  describe "authorization" do
    it "blocks a non-admin from the index" do
      coordinator = create(:user)
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      sign_in_as(coordinator)

      get account_users_path

      expect(response).to redirect_to(root_path)
    end

    it "lets an admin view the index" do
      sign_in_as(admin)

      get account_users_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "listing" do
    it "shows admins and coordinators but never a liaison's login" do
      coordinator = create(:user, name: "Cora Coordinator")
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      liaison = create(:liaison, account: account)
      sign_in_as(admin)

      get account_users_path

      expect(response.body).to include(coordinator.name)
      expect(response.body).not_to include(liaison.user.name)
    end
  end

  describe "create" do
    it "adds a new coordinator to the account" do
      sign_in_as(admin)

      expect {
        post account_users_path, params: { user: { name: "Jamie Coordinator", email_address: "jamie@example.com" }, role: "coordinator" }
      }.to change(User, :count).by(1)

      new_user = User.find_by(email_address: "jamie@example.com")
      membership = AccountMembership.find_by(user: new_user, account: account)
      expect(membership).to be_coordinator
      expect(response).to redirect_to(account_users_path)
    end

    it "rejects a submitted role of liaison" do
      sign_in_as(admin)

      expect {
        post account_users_path, params: { user: { name: "Sneaky", email_address: "sneaky@example.com" }, role: "liaison" }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "attaches an existing user from another account instead of failing on email uniqueness" do
      other_account = create(:account)
      existing = create(:user, :admin, account: other_account, name: "Multi Org Pat")
      sign_in_as(admin)

      expect {
        post account_users_path, params: { user: { name: existing.name, email_address: existing.email_address }, role: "coordinator" }
      }.not_to change(User, :count)

      expect(existing.accounts).to contain_exactly(other_account, account)
      expect(response).to redirect_to(account_users_path)
    end
  end

  describe "update" do
    it "changes another teammate's role" do
      coordinator = create(:user)
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      sign_in_as(admin)

      patch membership_path_for(coordinator), params: { role: "admin" }

      expect(AccountMembership.find_by(user: coordinator, account: account)).to be_admin
      expect(response).to redirect_to(account_users_path)
    end

    it "refuses to let an admin change their own role" do
      sign_in_as(admin)

      patch membership_path_for(admin), params: { role: "coordinator" }

      expect(AccountMembership.find_by(user: admin, account: account)).to be_admin
      expect(response).to redirect_to(account_users_path)
    end

    it "rejects a submitted role of liaison" do
      coordinator = create(:user)
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      sign_in_as(admin)

      patch membership_path_for(coordinator), params: { role: "liaison" }

      expect(AccountMembership.find_by(user: coordinator, account: account)).to be_coordinator
    end

    it "can't reach a liaison's login through this controller" do
      liaison = create(:liaison, account: account)
      sign_in_as(admin)

      patch membership_path_for(liaison.user), params: { role: "admin" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "destroy" do
    it "removes another admin/coordinator's access without deleting their login" do
      coordinator = create(:user)
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      sign_in_as(admin)

      expect {
        expect { delete membership_path_for(coordinator) }.to change(AccountMembership, :count).by(-1)
      }.not_to change(User, :count)
    end

    it "refuses to let an admin remove their own access" do
      sign_in_as(admin)

      expect { delete membership_path_for(admin) }.not_to change(AccountMembership, :count)
      expect(response).to redirect_to(account_users_path)
    end

    it "can't reach a liaison's login through this controller" do
      liaison = create(:liaison, account: account)
      sign_in_as(admin)

      delete membership_path_for(liaison.user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "tenant isolation" do
    it "can't list, add to, or remove from another account" do
      other_account = create(:account)
      other_admin = create(:user, :admin, account: other_account)
      sign_in_as(admin)

      get account_users_path
      expect(response.body).not_to include(other_admin.name)

      delete membership_path_for(other_admin, other_account)
      expect(response).to have_http_status(:not_found)
    end
  end
end
