FactoryBot.define do
  factory :assignment_setting do
    account { association :account }
    work_weeks_per_year { 46 }
    weekly_target { 2 }
  end
end
