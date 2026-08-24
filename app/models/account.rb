class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :liaisons, dependent: :destroy
  has_many :material_items, dependent: :destroy
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
