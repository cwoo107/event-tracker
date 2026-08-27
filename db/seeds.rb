# db:seed is meant to produce one known, reproducible starting state, not
# to accumulate on top of whatever's already there (accounts/users left
# over from manual testing, a stale historical-events import, etc.) - so
# every run wipes the database first. This is intentionally allowed to
# run in production: this file's content (the real USAN Marketing &
# Education account, its actual staff, and its real historical event log
# import - see db/seeds/liaisons.rb and db/seeds/historical_events.rb) is
# what gets delivered to that customer, not throwaway demo data. Only run
# this against a database you actually intend to wipe and replace with
# that starting state.
#
# The wipe and the fresh baseline it's replaced by are one transaction,
# not two separate steps - this file gets killed by a deploy-time timeout
# often enough in practice (the Mapbox backfill below alone takes a few
# minutes) that "wiped, but never got to reseed" has to be impossible.
# Whatever interrupts this run, the database ends up either exactly as it
# was before or fully reset - never caught in between.
#
# Account.destroy_all cascades to everything hung off an account (events
# and everything under them, liaisons, material_items, event_types,
# assignment_rules/settings, risk_thresholds, scoring_weights,
# account_memberships, sessions) - see Account's has_many declarations.
# The only thing left afterward is Users themselves, since a User can
# belong to more than one account and isn't destroyed just because one
# of their accounts is gone.
ActiveRecord::Base.transaction do
  Account.destroy_all
  User.destroy_all

  # One Account for the original organization's data - a top-level
  # constant (rather than a local variable) so it's visible from the
  # `load`ed seed files below, which each run in their own top-level
  # binding and can't see this file's locals. The office location matches
  # what AddOfficeLocationToAccounts backfilled onto the real "USAN"
  # account, so a fresh `db:seed` run reproduces the same starting state
  # as that migration did for the existing database.
  DEFAULT_ACCOUNT = Account.create!(name: "USAN Marketing & Education") do |account|
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

  # Liaisons, same transaction - fast, and every write in it needs the
  # same all-or-nothing guarantee as the wipe/recreate above.
  load Rails.root.join("db/seeds/liaisons.rb")
end

# Deliberately OUTSIDE the transaction above: this makes 130+ sequential,
# synchronous Mapbox API calls and can take a few minutes (see its own
# header comment) - holding a database transaction open across that much
# external I/O risks connection pool exhaustion, not something worth
# trading for atomicity here. It doesn't need it anyway - event import is
# idempotent (skips rows already present by title + start time) and the
# drive-time backfill is explicitly safe to rerun, so an interruption
# here just means running `bin/rails db:seed` again picks up cleanly
# (through a full fresh wipe, same as any other run) rather than leaving
# anything corrupted.
load Rails.root.join("db/seeds/historical_events.rb")
