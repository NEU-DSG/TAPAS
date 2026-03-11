FactoryBot.define do
  factory :project do
    sequence(:title) { |n| "Test Project #{n}" }
    association :depositor, factory: :user
  end
end
