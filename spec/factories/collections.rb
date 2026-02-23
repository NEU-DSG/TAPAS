FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "Test Collection #{n}" }
    association :depositor, factory: :user
    association :project
  end
end
