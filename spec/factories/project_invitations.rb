FactoryBot.define do
  factory :project_invitation do
    association :project
    association :creator, factory: :user

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :revoked do
      revoked_at { 1.hour.ago }
    end
  end
end
