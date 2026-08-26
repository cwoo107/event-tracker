FactoryBot.define do
  factory :account_membership do
    account { association :account }
    user { association :user }
    role { :coordinator }
  end
end
