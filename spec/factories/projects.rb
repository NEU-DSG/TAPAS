FactoryBot.define do
  factory :project do
    sequence(:title) { |n| "Test Project #{n}" }
    association :depositor, factory: :user
    is_public { true }
    description { "A test project description" }
  end
end
