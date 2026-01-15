FactoryBot.define do
  factory :project_member do
    association :project
    association :user
    role { "contributor" }
    is_project_depositor { false }

    trait :owner do
      role { "owner" }
      is_project_depositor { true }
    end

    trait :contributor do
      role { "contributor" }
    end
  end
end
