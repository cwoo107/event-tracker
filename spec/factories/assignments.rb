FactoryBot.define do
  factory :assignment do
    event
    liaison
    assigned_by { association :user, :admin }
    assignment_method { :manual }
    score { 87.5 }
    score_breakdown { { "drive_time" => 20, "weekly_pacing" => 30 } }
  end
end
