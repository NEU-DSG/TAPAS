FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    sequence(:name) { |n| "Test User #{n}" }

    trait :admin do
      admin { true }
      admin_at { Time.current }
    end
  end
end
