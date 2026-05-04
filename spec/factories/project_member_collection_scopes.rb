FactoryBot.define do
  factory :project_member_collection_scope do
    association :project_member
    association :collection
  end
end
