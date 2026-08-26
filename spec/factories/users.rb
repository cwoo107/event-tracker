FactoryBot.define do
  factory :user do
    transient do
      account { association :account }
    end

    sequence(:email_address) { |n| "user#{n}@usanmarketing.example" }
    sequence(:name) { |n| "Test User #{n}" }
    password { "password123" }

    trait :liaison_role do
      after(:create) { |user, evaluator| create(:account_membership, user: user, role: :liaison, account: evaluator.account) }
    end

    trait :admin do
      after(:create) { |user, evaluator| create(:account_membership, user: user, role: :admin, account: evaluator.account) }
    end
  end
end
