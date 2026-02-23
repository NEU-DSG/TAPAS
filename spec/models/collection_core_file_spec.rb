# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionCoreFile, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:collection) }
    it { is_expected.to belong_to(:core_file) }
  end

  describe '#core_file_project_matches_collection_project' do
    let(:depositor) { create(:user) }
    let(:project_a) { create(:project, depositor: depositor) }
    let(:project_b) { create(:project, depositor: depositor) }
    let(:collection_a) { create(:collection, project: project_a, depositor: depositor) }
    let(:collection_b) { create(:collection, project: project_b, depositor: depositor) }
    let(:core_file) { create(:core_file, depositor: depositor, collections: [ collection_a ]) }

    it 'allows adding a collection from the same project' do
      same_project_collection = create(:collection, project: project_a, depositor: depositor)
      join = CollectionCoreFile.new(core_file: core_file, collection: same_project_collection)
      expect(join).to be_valid
    end

    it 'rejects a collection from a different project' do
      join = CollectionCoreFile.new(core_file: core_file, collection: collection_b)
      expect(join).not_to be_valid
      expect(join.errors[:base].first).to include("same project")
    end

    it 'is valid when core file has no other collections' do
      new_depositor = create(:user)
      new_project = create(:project, depositor: new_depositor)
      new_collection = create(:collection, project: new_project, depositor: new_depositor)

      # Create directly to bypass factory after(:build) which auto-adds collections
      new_core_file = CoreFile.create!(
        title: 'Orphan Core File',
        depositor: new_depositor,
        processing_status: 'pending'
      )

      join = CollectionCoreFile.new(core_file: new_core_file, collection: new_collection)
      expect(join).to be_valid
    end
  end
end
