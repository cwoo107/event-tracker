FactoryBot.define do
  factory :event_type do
    account { association :account }
    sequence(:name) { |n| "Test Event Type #{n}" }
    active { true }
  end
end
