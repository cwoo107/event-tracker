FactoryBot.define do
  factory :user do
    account { association :account }
    sequence(:email_address) { |n| "user#{n}@usanmarketing.example" }
    sequence(:name) { |n| "Test User #{n}" }
    password { "password123" }
    role { :coordinator }

    trait :liaison_role do
      role { :liaison }
    end

    trait :admin do
      role { :admin }
    end
  end
end
