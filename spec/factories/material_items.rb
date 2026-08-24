FactoryBot.define do
  factory :material_item do
    account { association :account }
    sequence(:name) { |n| "Material #{n}" }
    category { "Signage" }
    active { true }
  end
end
