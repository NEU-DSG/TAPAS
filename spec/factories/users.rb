FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    account_status { :active }

    trait :admin do
      admin_at { Time.current }
    end

    trait :pending_review do
      account_status { :pending_review }
    end
  end
end
