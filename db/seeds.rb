# Populates AssignmentSetting, ScoringWeight, and AssignmentRule with the
# exact values shown on the Settings screen mockup. The actual default
# values live in SettingsForm (shared with the Settings screen's "Reset to
# defaults" button) so this file and that button can't drift apart.
SettingsForm.reset_to_defaults!

# Users, liaisons, the material catalog, and (if db/seed_data/events.csv
# is present) the historical event import - see each file's header
# comment for what it does and the judgment calls it makes along the way.
load Rails.root.join("db/seeds/liaisons.rb")
load Rails.root.join("db/seeds/material_items.rb")
load Rails.root.join("db/seeds/historical_events.rb")
