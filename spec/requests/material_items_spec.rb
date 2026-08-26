require "rails_helper"

RSpec.describe "Material items", type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :admin, account: account) }

  describe "authorization" do
    it "blocks a non-admin" do
      coordinator = create(:user)
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      sign_in_as(coordinator)

      post material_items_path, params: { material_item: { name: "Koozies" } }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "create" do
    it "adds a new material item" do
      sign_in_as(admin)

      expect {
        post material_items_path, params: { material_item: { name: "Koozies" } }
      }.to change(account.material_items, :count).by(1)

      expect(response).to redirect_to(account_users_path)
    end

    it "shows a duplicate name error inline within the frame" do
      create(:material_item, account: account, name: "Koozies")
      sign_in_as(admin)

      expect {
        post material_items_path, params: { material_item: { name: "Koozies" } }
      }.not_to change(account.material_items, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="material_items_frame"')
      expect(response.body).to include("Name has already been taken")
    end
  end

  describe "update" do
    it "toggles active" do
      material_item = create(:material_item, account: account, active: true)
      sign_in_as(admin)

      patch material_item_path(material_item), params: { active: "false" }

      expect(material_item.reload).not_to be_active
    end
  end

  describe "destroy" do
    it "removes an unused material item" do
      material_item = create(:material_item, account: account)
      sign_in_as(admin)

      expect { delete material_item_path(material_item) }.to change(MaterialItem, :count).by(-1)
    end

    it "refuses to delete one still referenced by events, inline in the frame" do
      material_item = create(:material_item, account: account)
      event = create(:event, account: account)
      create(:event_material_item, event: event, material_item: material_item)
      sign_in_as(admin)

      expect { delete material_item_path(material_item) }.not_to change(MaterialItem, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="material_items_frame"')
      expect(response.body).to include("is used by existing events")
    end
  end
end
