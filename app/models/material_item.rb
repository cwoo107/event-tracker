class MaterialItem < ApplicationRecord
  include Activatable

  has_many :event_material_items, dependent: :destroy
  has_many :events, through: :event_material_items

  validates :name, presence: true, uniqueness: true
end
