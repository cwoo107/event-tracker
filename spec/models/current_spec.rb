require "rails_helper"

RSpec.describe Current, type: :model do
  # CurrentAttributes.reset (called between every request) only clears
  # state declared via `attribute` - a memoized bare @ivar on #membership
  # or #liaison would survive it and leak one user's admin/liaison status
  # into the next request handled by the same thread. This reproduces
  # that request-boundary at the model layer via Current.reset.
  it "never leaks one session's membership/liaison into the next after reset" do
    account = create(:account)
    admin = create(:user, :admin, account: account)
    coordinator = create(:user)
    create(:account_membership, user: coordinator, account: account, role: :coordinator)

    Current.session = admin.sessions.create!(account: account)
    expect(Current).to be_admin

    Current.reset
    Current.session = coordinator.sessions.create!(account: account)

    expect(Current).not_to be_admin
  end
end
