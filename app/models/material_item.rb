class MaterialItem < ApplicationRecord
  include Activatable

  # The full promotional-materials catalog every new account starts
  # with - seeded by Account#seed_defaults!, called both from
  # db/seeds.rb and from signup (RegistrationsController).
  DEFAULT_CATALOG = [
    "811 Sticker (2.5)", "811 Sticker (6)", "811 Sticker (9)", "Chip Clips",
    "Color Code Magnets", "Color Code Stickers", "Dip Trips",
    "Field Guides - California", "Field Guides - Nevada", "Keychains", "Koozies",
    "Manuals - California", "Manuals - Nevada", "Pop Sockets", "Rally Towels",
    "Slap Bracelets", "Stress Balls - Soccer", "Sunglasses", "Water Bottles"
  ].freeze

  belongs_to :account
  has_many :event_material_items, dependent: :destroy
  has_many :events, through: :event_material_items

  validates :name, presence: true, uniqueness: { scope: :account_id }
end
