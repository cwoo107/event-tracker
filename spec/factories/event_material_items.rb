FactoryBot.define do
  factory :event_material_item do
    event
    material_item
    quantity { 1 }
    checked { false }
  end
end
