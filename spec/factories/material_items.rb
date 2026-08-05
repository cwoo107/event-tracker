FactoryBot.define do
  factory :material_item do
    sequence(:name) { |n| "Material #{n}" }
    category { "Signage" }
    active { true }
  end
end
