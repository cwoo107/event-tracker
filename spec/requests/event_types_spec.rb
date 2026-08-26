require "rails_helper"

RSpec.describe "Event types", type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :admin, account: account) }

  describe "authorization" do
    it "blocks a non-admin" do
      coordinator = create(:user)
      create(:account_membership, user: coordinator, account: account, role: :coordinator)
      sign_in_as(coordinator)

      post event_types_path, params: { event_type: { name: "Webinar" } }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "create" do
    it "adds a new event type, rendered inside its turbo frame" do
      sign_in_as(admin)

      expect {
        post event_types_path, params: { event_type: { name: "Site visit" } }
      }.to change(account.event_types, :count).by(1)

      expect(response).to redirect_to(account_users_path)
    end

    it "shows a duplicate name error inline within the frame instead of losing it to a flash-only redirect" do
      create(:event_type, account: account, name: "Site visit")
      sign_in_as(admin)

      expect {
        post event_types_path, params: { event_type: { name: "Site visit" } }
      }.not_to change(account.event_types, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="event_types_frame"')
      expect(response.body).to include("Name has already been taken")
    end
  end

  describe "update" do
    it "toggles active" do
      event_type = create(:event_type, account: account, active: true)
      sign_in_as(admin)

      patch event_type_path(event_type), params: { active: "false" }

      expect(event_type.reload).not_to be_active
    end
  end

  describe "destroy" do
    it "removes an unused event type" do
      event_type = create(:event_type, account: account)
      sign_in_as(admin)

      expect { delete event_type_path(event_type) }.to change(EventType, :count).by(-1)
    end

    it "refuses to delete one still referenced by events, inline in the frame" do
      event_type = create(:event_type, account: account)
      create(:event, account: account, event_type: event_type)
      sign_in_as(admin)

      expect { delete event_type_path(event_type) }.not_to change(EventType, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('id="event_types_frame"')
      expect(response.body).to include("is used by existing events")
    end
  end
end
