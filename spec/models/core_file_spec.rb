require 'rails_helper'

RSpec.describe CoreFile, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:depositor_id) }

    it 'validates processing_status inclusion' do
      core_file = build(:core_file, processing_status: 'invalid')
      expect(core_file).not_to be_valid
      expect(core_file.errors[:processing_status]).to be_present
    end

    it 'allows valid processing statuses' do
      CoreFile::PROCESSING_STATUSES.each do |status|
        core_file = build(:core_file, processing_status: status)
        core_file.valid?
        expect(core_file.errors[:processing_status]).to be_empty
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('User') }
    it { is_expected.to have_many(:collections) }
    it { is_expected.to have_many(:collection_core_files) }
    it { is_expected.to have_one(:image_file) }
  end

  describe 'scopes' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) { create(:collection, project: project, depositor: depositor) }

    let!(:pending_file) do
      create(:core_file, depositor: depositor, collections: [ collection ], processing_status: 'pending')
    end

    let!(:failed_file) do
      create(:core_file, depositor: depositor, collections: [ collection ], processing_status: 'failed')
    end

    let!(:completed_file) do
      create(:core_file, depositor: depositor, collections: [ collection ], processing_status: 'completed')
    end

    describe '.processing_pending' do
      it 'returns pending files' do
        expect(CoreFile.processing_pending).to include(pending_file)
        expect(CoreFile.processing_pending).not_to include(failed_file, completed_file)
      end
    end

    describe '.processing_failed' do
      it 'returns failed files' do
        expect(CoreFile.processing_failed).to include(failed_file)
        expect(CoreFile.processing_failed).not_to include(pending_file, completed_file)
      end
    end

    describe '.processing_completed' do
      it 'returns completed files' do
        expect(CoreFile.processing_completed).to include(completed_file)
        expect(CoreFile.processing_completed).not_to include(pending_file, failed_file)
      end
    end
  end

  describe 'callbacks' do
    describe '#enqueue_tapas_xq_processing' do
      let(:depositor) { create(:user) }
      let(:project) { create(:project, depositor: depositor) }
      let(:collection) { create(:collection, project: project, depositor: depositor) }

      it 'enqueues ProcessTeiFileJob after create when TEI attached' do
        core_file = build(:core_file, depositor: depositor, collections: [ collection ])
        core_file.tei_file.attach(
          io: StringIO.new("<TEI></TEI>"),
          filename: "test.xml",
          content_type: "application/xml"
        )

        expect {
          core_file.save!
        }.to have_enqueued_job(ProcessTeiFileJob)
      end

      it 'does not enqueue job if TEI file not attached' do
        expect {
          create(:core_file, depositor: depositor, collections: [ collection ])
        }.not_to have_enqueued_job(ProcessTeiFileJob)
      end
    end
  end

  describe '#processing_pending?' do
    it 'returns true when status is pending' do
      core_file = build(:core_file, processing_status: 'pending')
      expect(core_file.processing_pending?).to be true
    end

    it 'returns false when status is not pending' do
      core_file = build(:core_file, processing_status: 'completed')
      expect(core_file.processing_pending?).to be false
    end
  end

  describe '#processing_failed?' do
    it 'returns true when status is failed' do
      core_file = build(:core_file, processing_status: 'failed')
      expect(core_file.processing_failed?).to be true
    end

    it 'returns false when status is not failed' do
      core_file = build(:core_file, processing_status: 'pending')
      expect(core_file.processing_failed?).to be false
    end
  end

  describe '#processing_completed?' do
    it 'returns true when status is completed' do
      core_file = build(:core_file, processing_status: 'completed')
      expect(core_file.processing_completed?).to be true
    end

    it 'returns false when status is not completed' do
      core_file = build(:core_file, processing_status: 'failed')
      expect(core_file.processing_completed?).to be false
    end
  end

  describe '#retry_processing!' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) { create(:collection, project: project, depositor: depositor) }

    context 'when processing failed' do
      let(:core_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: 'failed',
          processing_error: 'Something went wrong'
        )
      end

      it 'resets status to pending' do
        core_file.retry_processing!
        expect(core_file.processing_status).to eq('pending')
      end

      it 'clears processing_error' do
        core_file.retry_processing!
        expect(core_file.processing_error).to be_nil
      end

      it 'enqueues ProcessTeiFileJob' do
        expect {
          core_file.retry_processing!
        }.to have_enqueued_job(ProcessTeiFileJob).with(core_file.id)
      end

      it 'returns true' do
        expect(core_file.retry_processing!).to be true
      end
    end

    context 'when processing not failed' do
      let(:core_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: 'completed'
        )
      end

      it 'does not change status' do
        core_file.retry_processing!
        expect(core_file.processing_status).to eq('completed')
      end

      it 'does not enqueue job' do
        expect {
          core_file.retry_processing!
        }.not_to have_enqueued_job(ProcessTeiFileJob)
      end

      it 'returns false' do
        expect(core_file.retry_processing!).to be false
      end
    end
  end

  describe '#project' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) { create(:collection, project: project, depositor: depositor) }
    let(:core_file) { create(:core_file, depositor: depositor, collections: [ collection ]) }

    it 'returns the project through first collection' do
      expect(core_file.project).to eq(project)
    end

    it 'returns nil if no collections' do
      core_file.collections.clear
      expect(core_file.project).to be_nil
    end
  end

  describe '.all_ography_types' do
    it 'returns the expected ography types' do
      expect(CoreFile.all_ography_types).to match_array(
        %w[personography orgography bibliography otherography odd_file placeography]
      )
    end
  end

  describe '#is_ography?' do
    it 'returns true when ography_type is present' do
      core_file = build(:core_file, ography_type: 'personography')
      expect(core_file.is_ography?).to be true
    end

    it 'returns false when ography_type is blank' do
      core_file = build(:core_file, ography_type: nil)
      expect(core_file.is_ography?).to be false
    end
  end

  describe '#is_ography_for' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) { create(:collection, project: project, depositor: depositor) }

    it 'returns collection ids when core file is an ography' do
      core_file = create(:core_file, depositor: depositor, collections: [ collection ], ography_type: 'personography')
      expect(core_file.is_ography_for).to eq(core_file.collection_ids)
    end

    it 'returns an empty array when core file is not an ography' do
      core_file = create(:core_file, depositor: depositor, collections: [ collection ], ography_type: nil)
      expect(core_file.is_ography_for).to eq([])
    end
  end

  describe 'collection presence validation' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) { create(:collection, project: project, depositor: depositor) }

    it 'does not require collections when not persisted' do
      core_file = CoreFile.new(title: 'Test', depositor: depositor, processing_status: 'pending')
      core_file.valid?
      expect(core_file.errors[:collections]).to be_empty
    end

    it 'is invalid without collections when persisted' do
      core_file = create(:core_file, depositor: depositor, collections: [ collection ])
      core_file.collections.clear
      expect(core_file).not_to be_valid
      expect(core_file.errors[:collections]).to be_present
    end
  end

  describe '#collections_same_project validation' do
    let(:depositor) { create(:user) }
    let(:project_a) { create(:project, depositor: depositor) }
    let(:project_b) { create(:project, depositor: depositor) }
    let(:collection_a) { create(:collection, project: project_a, depositor: depositor) }
    let(:collection_b) { create(:collection, project: project_b, depositor: depositor) }

    it 'is valid when all collections belong to the same project' do
      collection_a2 = create(:collection, project: project_a, depositor: depositor)
      core_file = build(:core_file, depositor: depositor, collections: [ collection_a, collection_a2 ])
      core_file.valid?
      expect(core_file.errors[:collections]).to be_empty
    end

    it 'is invalid when collections belong to different projects' do
      core_file = build(:core_file, depositor: depositor, collections: [ collection_a, collection_b ])
      expect(core_file).not_to be_valid
      expect(core_file.errors[:collections]).to include("must all belong to the same project")
    end
  end

  describe '#to_solr' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) { create(:collection, project: project, depositor: depositor) }
    let(:core_file) do
      create(:core_file,
        depositor: depositor,
        collections: [ collection ],
        title: 'Solr Test Core File',
        is_public: true,
        ography_type: nil
      )
    end

    it 'returns a complete solr document' do
      doc = core_file.to_solr
      expect(doc["active_record_model_ssi"]).to eq("CoreFile")
      expect(doc["depositor_tesim"]).to eq(depositor.id)
      expect(doc["table_id_ssi"]).to eq(core_file.id)
      expect(doc["id"]).to eq("CoreFile_#{core_file.id}")
      expect(doc["edit_access_person_ssim"]).to eq(depositor.id)
      expect(doc["collections_ssim"]).to eq(core_file.collections.map(&:id))
      expect(doc["project_ssim"]).to eq(project.id)
      expect(doc["title_info_title_ssi"]).to eq("Solr Test Core File")
      expect(doc["type_ssim"]).to eq("TEI Record")
      expect(doc["access_ssim"]).to eq("public")
      expect(doc["image_file_ssi"]).to eq("public/assets/logo_no_text.png")
    end

    context 'when core file is an ography' do
      let(:ography_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          ography_type: 'personography'
        )
      end

      it 'sets type_ssim to the ography type' do
        doc = ography_file.to_solr
        expect(doc["type_ssim"]).to eq("personography")
      end

      it 'sets is_ography_for_ssim to collection ids' do
        doc = ography_file.to_solr
        expect(doc["is_ography_for_ssim"]).to eq(ography_file.collection_ids)
      end
    end

    context 'when core file is private' do
      let(:private_file) do
        create(:core_file, depositor: depositor, collections: [ collection ], is_public: false)
      end

      it 'sets access to private' do
        doc = private_file.to_solr
        expect(doc["access_ssim"]).to eq("private")
      end
    end
  end
end
