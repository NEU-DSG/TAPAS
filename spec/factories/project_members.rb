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

    trait :pending do
      status { :pending }
    end
  end
end
