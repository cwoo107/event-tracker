require "rails_helper"

# Proves the "no one can see each other's data" requirement actually
# holds at the controller layer, where account-scoping is enforced by
# convention (Current.account.<association>) rather than a framework -
# these are the specs that would catch a regression to a bare
# Model.find/Model.where call anywhere in that chain.
RSpec.describe "Tenant isolation", type: :request do
  let(:account_a) { create(:account) }
  let(:account_b) { create(:account) }
  let(:admin_a) { create(:user, :admin, account: account_a) }

  before do
    account_a.seed_defaults!
    account_b.seed_defaults!
  end

  it "404s when requesting another account's event by id" do
    other_event = create(:event, account: account_b)
    sign_in_as(admin_a)

    get event_path(other_event)

    expect(response).to have_http_status(:not_found)
  end

  it "404s when requesting another account's liaison by id" do
    other_liaison = create(:liaison, account: account_b)
    sign_in_as(admin_a)

    get liaison_path(other_liaison)

    expect(response).to have_http_status(:not_found)
  end

  it "never lists another account's events in the map sidebar" do
    own_event = create(:event, account: account_a, title: "Account A Only Event")
    other_event = create(:event, account: account_b, title: "Account B Only Event")
    sign_in_as(admin_a)

    get map_path

    expect(response.body).to include(own_event.title)
    expect(response.body).not_to include(other_event.title)
  end

  it "keeps settings updates scoped to the acting account" do
    sign_in_as(admin_a)

    patch settings_path, params: {
      weights: { "drive_time" => "55" },
      work_weeks_per_year: 46, weekly_target: 2
    }

    expect(account_a.scoring_weights.find_by(criterion: "drive_time").weight).to eq(55)
    expect(account_b.scoring_weights.find_by(criterion: "drive_time").weight).to eq(30) # untouched default
  end

  it "never returns a candidate from another account, even a higher-scoring one" do
    event = create(:event, account: account_a)
    account_a.scoring_weights.find_by(criterion: "weekly_load_balance").update!(weight: 100)
    in_account_liaison = create(:liaison, account: account_a)
    other_account_liaison = create(:liaison, account: account_b)

    ranking = Scoring::Ranking.new(event)

    expect(ranking.candidates.map(&:liaison)).to eq([in_account_liaison])
    expect(ranking.candidates.map(&:liaison)).not_to include(other_account_liaison)
  end
end
