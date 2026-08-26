class EventType < ApplicationRecord
  include Activatable

  # What a fresh account starts with - the same 8 values the app used to
  # ship as a single fixed enum shared by every account (see
  # BackfillEventTypeIds for the historical mapping this mirrors).
  # Seeded by Account#seed_defaults!, same pattern as MaterialItem.
  DEFAULT_CATALOG = [
    "Direct presentation", "Industry tabling", "Industry networking",
    "Office visit cold", "Public outreach tabling", "Safe event",
    "Site visit", "Webinar"
  ].freeze

  belongs_to :account
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :account_id }
end
