FactoryBot.define do
  factory :liaison do
    account { association :account }
    user { association :user, :liaison_role, account: account }
    sequence(:color) { |n| format("#%06x", (n * 111_111) % 0xFFFFFF) }
    region { Liaison::REGIONS.first }
    home_city { "Elk Grove" }
    skills { [] }
    active { true }
  end
end
