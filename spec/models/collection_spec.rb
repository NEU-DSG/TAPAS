# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:depositor_id) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('User') }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:image_file) }
    it { is_expected.to have_many(:collection_core_files).dependent(:destroy) }
    it { is_expected.to have_many(:core_files).through(:collection_core_files) }
  end

  describe 'project membership constraint' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:contributor) { create(:user) }
    let(:non_member) { create(:user) }

    before do
      create(:project_member, :contributor, project: project, user: contributor)
    end

    it 'is valid when the depositor is a project owner' do
      collection = build(:collection, project: project, depositor: depositor)
      expect(collection).to be_valid
    end

    it 'is valid when the depositor is a project contributor' do
      collection = build(:collection, project: project, depositor: contributor)
      expect(collection).to be_valid
    end

    it 'is invalid when the depositor is not a project member' do
      collection = build(:collection, project: project, depositor: non_member)
      expect(collection).not_to be_valid
      expect(collection.errors[:depositor]).to be_present
    end
  end

  describe 'project visibility constraint' do
    let(:depositor) { create(:user) }
    let(:private_project) { create(:project, depositor: depositor, is_public: false) }
    let(:public_project) { create(:project, depositor: depositor, is_public: true) }

    it 'is invalid when public and the project is private' do
      collection = build(:collection, project: private_project, depositor: depositor, is_public: true)
      expect(collection).not_to be_valid
      expect(collection.errors[:is_public]).to be_present
    end

    it 'is valid when private and the project is private' do
      collection = build(:collection, project: private_project, depositor: depositor, is_public: false)
      expect(collection).to be_valid
    end

    it 'is valid when public and the project is public' do
      collection = build(:collection, project: public_project, depositor: depositor, is_public: true)
      expect(collection).to be_valid
    end
  end

  describe '#to_solr' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:collection) do
      create(:collection, depositor: depositor, project: project, title: 'Solr Test Collection', is_public: true)
    end

    it 'returns a complete solr document' do
      doc = collection.to_solr
      expect(doc["active_record_model_ssi"]).to eq("Collection")
      expect(doc["depositor_tesim"]).to eq(depositor.id)
      expect(doc["table_id_ssi"]).to eq(collection.id)
      expect(doc["id"]).to eq("Collection_#{collection.id}")
      expect(doc["edit_access_person_ssim"]).to eq(depositor.id)
      expect(doc["project_ssim"]).to eq(project.id)
      expect(doc["title_info_title_ssi"]).to eq("Solr Test Collection")
      expect(doc["access_ssim"]).to eq("public")
      expect(doc["image_file_ssi"]).to eq("public/assets/logo_no_text.png")
    end

    context 'when collection is private' do
      let(:private_collection) do
        create(:collection, depositor: depositor, project: project, is_public: false)
      end

      it 'sets access to private' do
        doc = private_collection.to_solr
        expect(doc["access_ssim"]).to eq("private")
      end
    end

    context 'when project has only the default owner' do
      let(:project_default_owner) { create(:project, depositor: depositor) }
      let(:collection_default_owner) do
        create(:collection, depositor: depositor, project: project_default_owner)
      end

      it 'uses the depositor as edit access person' do
        doc = collection_default_owner.to_solr
        expect(doc["edit_access_person_ssim"]).to eq(depositor.id)
      end
    end
  end
end
