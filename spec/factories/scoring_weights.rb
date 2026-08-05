FactoryBot.define do
  factory :scoring_weight do
    criterion { "drive_time" }
    weight { 1.0 }
  end
end
