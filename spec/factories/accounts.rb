FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Test Org #{n}" }
    office_address { "4005 Port Chicago Hwy" }
    office_city { "Concord" }
    office_state { "CA" }
    office_zip { "94520" }
    office_latitude { 38.0116 }
    office_longitude { -122.0247 }
  end
end
