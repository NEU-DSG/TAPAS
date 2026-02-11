FactoryBot.define do
  factory :core_file do
    sequence(:title) { |n| "Test Core File #{n}" }
    depositor { association :user, strategy: :create }

    after(:build) do |core_file|
      if core_file.collections.empty?
        project = create(:project, depositor: core_file.depositor)
        core_file.collections << build(:collection, project: project, depositor: core_file.depositor)
      end
    end
  end
end
