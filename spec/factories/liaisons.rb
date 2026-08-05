FactoryBot.define do
  factory :liaison do
    user { association :user, :liaison_role }
    sequence(:color) { |n| format("#%06x", (n * 111_111) % 0xFFFFFF) }
    region { Liaison::REGIONS.first }
    home_city { "Elk Grove" }
    skills { [] }
    active { true }
  end
end
