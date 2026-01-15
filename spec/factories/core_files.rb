FactoryBot.define do
  factory :core_file do
    sequence(:title) { |n| "Test Core File #{n}" }
    association :depositor, factory: :user
    processing_status { "pending" }
    is_public { true }
    description { "A test core file description" }

    transient do
      collections_count { 1 }
      project { nil }
    end

    after(:build) do |core_file, evaluator|
      if core_file.collections.empty?
        # Ensure depositor is saved before creating dependent records
        core_file.depositor.save! unless core_file.depositor.persisted?
        project = evaluator.project || create(:project, depositor: core_file.depositor)
        evaluator.collections_count.times do
          core_file.collections << build(:collection, project: project, depositor: core_file.depositor)
        end
      end
    end

    trait :with_tei_file do
      after(:build) do |core_file|
        core_file.tei_file.attach(
          io: StringIO.new('<?xml version="1.0"?><TEI xmlns="http://www.tei-c.org/ns/1.0"><text><body><p>Test TEI</p></body></text></TEI>'),
          filename: 'test.xml',
          content_type: 'application/xml'
        )
      end
    end

    trait :processing do
      processing_status { "processing" }
    end

    trait :completed do
      processing_status { "completed" }
    end

    trait :failed do
      processing_status { "failed" }
      processing_error { "Test error message" }
    end
  end
end
