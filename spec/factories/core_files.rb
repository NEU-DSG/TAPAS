FactoryBot.define do
  factory :core_file do
    sequence(:title) { |n| "Test Core File #{n}" }
    depositor { association :user, strategy: :create }
  end
end
