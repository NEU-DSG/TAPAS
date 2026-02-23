FactoryBot.define do
  factory :tei_file, class: CoreFile do
    sequence(:title) { |n| "Test TEI File #{n}" }
    depositor { association :user, strategy: :create }

    after(:build) do |core_file|
      if core_file.collections.empty?
        project = create(:project, depositor: core_file.depositor)
        core_file.collections << build(:collection, project: project, depositor: core_file.depositor)
      end
    end

    after(:create) do |core_file|
      core_file.tei_file.attach(
        io: StringIO.new("<TEI><teiHeader><title>#{core_file.title}</title></teiHeader></TEI>"),
        filename: "tei_file.xml",
        content_type: "application/xml"
      )
    end
  end
end
