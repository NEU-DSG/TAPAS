FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "Test Collection #{n}" }
    association :depositor, factory: :user
    association :project
    is_public { true }
    description { "A test collection description" }
  end
end
