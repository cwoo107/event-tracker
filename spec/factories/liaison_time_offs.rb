FactoryBot.define do
  factory :liaison_time_off do
    liaison
    starts_on { Date.current }
    ends_on { Date.current + 6.days }
    reason { "Vacation" }
  end
end
