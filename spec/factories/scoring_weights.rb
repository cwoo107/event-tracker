FactoryBot.define do
  factory :scoring_weight do
    account { association :account }
    criterion { "drive_time" }
    weight { 1.0 }
  end
end
