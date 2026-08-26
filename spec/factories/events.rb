FactoryBot.define do
  factory :event do
    account { association :account }
    title { "811 Safety Training" }
    event_type { association :event_type, account: account }
    status { :unassigned }
    source { :manual }
    starts_at { 1.week.from_now.change(hour: 10) }
    ends_at { 1.week.from_now.change(hour: 12) }
    prep_minutes { 30 }
    teardown_minutes { 30 }
    location { RGeo::Geographic.spherical_factory(srid: 4326).point(-121.4944, 38.5816) } # Sacramento
    county { "Sacramento" }
    requester_name { "Jane Requester" }
    requester_email { "jane@example.com" }

    trait :assigned do
      status { :assigned }

      after(:create) do |event|
        admin = create(:user, :admin, account: event.account)
        event.assign_to!(create(:liaison, account: event.account), by: admin, assignment_method: :manual)
      end
    end

    trait :weekend do
      starts_at { Date.current.next_occurring(:saturday).to_time.change(hour: 10) }
      ends_at { Date.current.next_occurring(:saturday).to_time.change(hour: 13) }
    end
  end
end
