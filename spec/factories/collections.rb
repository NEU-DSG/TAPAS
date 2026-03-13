FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "Test Collection #{n}" }
    description { "A test collection description" }
    is_public { true }
    association :depositor, factory: :user
    project { association(:project, depositor: depositor) }
  end
end
