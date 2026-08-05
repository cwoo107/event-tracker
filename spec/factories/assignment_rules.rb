FactoryBot.define do
  factory :assignment_rule do
    key { "max_weekly_events" }
    enabled { true }
    threshold { 3 }
  end
end
