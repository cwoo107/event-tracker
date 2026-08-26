class Account < ApplicationRecord
  has_many :account_memberships, dependent: :destroy
  # Deliberately no dependent: :destroy here - a User is shared across
  # accounts now, so destroying an Account should only remove people's
  # membership to it (handled by account_memberships' own
  # dependent: :destroy above), never their login itself.
  has_many :users, through: :account_memberships
  # A session is "pinned" to whichever account is currently active (see
  # Current#account) - if that account goes away, the session pointing at
  # it has to go too, rather than leaving a dangling reference. The
  # affected person just signs back in and lands on one of their
  # remaining accounts.
  has_many :sessions, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :liaisons, dependent: :destroy
  has_many :material_items, dependent: :destroy
  has_many :event_types, dependent: :destroy
  has_many :assignment_rules, dependent: :destroy
  has_many :risk_thresholds, dependent: :destroy
  has_many :scoring_weights, dependent: :destroy
  has_one :assignment_setting, dependent: :destroy

  validates :name, presence: true

  before_validation :build_office_location_from_coordinates

  # Virtual attributes for the settings form's geocoded office
  # coordinates - same pattern as Event's #latitude=/#longitude=, since
  # office_location is stored as a single geography point.
  attr_writer :office_latitude, :office_longitude

  # What a fresh account starts with - the same defaults db/seeds.rb
  # applies to the original organization's account, so there's one
  # source of truth for "what does a new account look like."
  def seed_defaults!
    SettingsForm.reset_to_defaults!(account: self)
    MaterialItem::DEFAULT_CATALOG.each { |name| material_items.find_or_create_by!(name: name) }
    EventType::DEFAULT_CATALOG.each { |name| event_types.find_or_create_by!(name: name) }
  end

  def office_latitude
    office_location&.y
  end

  def office_longitude
    office_location&.x
  end

  private

  def build_office_location_from_coordinates
    return if @office_latitude.blank? || @office_longitude.blank?

    self.office_location = RGeo::Geographic.spherical_factory(srid: 4326).point(@office_longitude.to_f, @office_latitude.to_f)
  end
end
