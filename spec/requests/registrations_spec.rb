require "rails_helper"

RSpec.describe "Registrations", type: :request do
  it "creates a fully seeded, isolated account and signs the new admin in" do
    existing_account = create(:account)
    existing_account.seed_defaults!
    existing_account.scoring_weights.find_by(criterion: "drive_time").update!(weight: 99)

    post registration_path, params: {
      account: { name: "New Org" },
      user: { name: "Jamie Admin", email_address: "jamie@neworg.example", password: "password123" }
    }

    expect(response).to redirect_to(root_path)

    new_account = Account.find_by!(name: "New Org")
    expect(new_account.account_memberships.sole).to be_admin
    expect(new_account.assignment_setting).to be_present
    expect(new_account.scoring_weights.find_by(criterion: "drive_time").weight).to eq(30)
    expect(new_account.material_items.count).to eq(MaterialItem::DEFAULT_CATALOG.size)
    expect(new_account.event_types.count).to eq(EventType::DEFAULT_CATALOG.size)

    # The existing account's own settings are untouched by the new signup
    expect(existing_account.scoring_weights.find_by(criterion: "drive_time").weight).to eq(99)
  end

  it "re-renders the form without creating anything on invalid input" do
    account_count = Account.count
    user_count = User.count

    post registration_path, params: {
      account: { name: "" },
      user: { name: "Jamie Admin", email_address: "jamie@neworg.example", password: "password123" }
    }

    expect(Account.count).to eq(account_count)
    expect(User.count).to eq(user_count)
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
