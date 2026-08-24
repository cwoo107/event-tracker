# One Account for the original organization's data - a top-level
# constant (rather than a local variable) so it's visible from the
# `load`ed seed files below, which each run in their own top-level
# binding and can't see this file's locals. The office location matches
# what AddOfficeLocationToAccounts backfilled onto the real "USAN"
# account, so a fresh `db:seed` run reproduces the same starting state
# as that migration did for the existing database.
DEFAULT_ACCOUNT = Account.find_or_create_by!(name: "USAN") do |account|
  account.office_address = "4005 Port Chicago Hwy"
  account.office_city = "Concord"
  account.office_state = "CA"
  account.office_zip = "94520"
  account.office_latitude = 38.0116
  account.office_longitude = -122.0247
end

# Populates AssignmentSetting, ScoringWeight, AssignmentRule, and the
# material catalog with the exact values shown on the Settings screen
# mockup. The actual defaults live in SettingsForm/MaterialItem (shared
# with the Settings screen's "Reset to defaults" button and new-account
# signup) so this file and those can't drift apart.
DEFAULT_ACCOUNT.seed_defaults!

# Users, liaisons, and (if db/seed_data/events.csv is present) the
# historical event import - see each file's header comment for what it
# does and the judgment calls it makes along the way.
load Rails.root.join("db/seeds/liaisons.rb")
load Rails.root.join("db/seeds/historical_events.rb")
