FactoryBot.define do
  factory :project_member do
    association :project
    association :user
    role { "contributor" }

    trait :owner do
      role { "owner" }
    end

    trait :contributor do
      role { "contributor" }
    end
  end
end
