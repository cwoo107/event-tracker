FactoryBot.define do
  factory :liaison_load_hold do
    liaison
    max_drive_minutes { 90 }
    block_weekends { true }
    ends_on { 2.weeks.from_now.to_date }
    reason { "3 events over pace" }
  end
end
