# frozen_string_literal: true

require 'rails_helper'

# Captured at load time, before rails_helper's global stub replaces it, so the
# real method can still be exercised below.
REAL_DELETE_RECORD = SolrHelpers.instance_method(:delete_record)

# Destroyed records must leave the Solr index, otherwise search keeps returning them.
RSpec.describe 'Solr removal on destroy', type: :model do
  let(:depositor) { create(:user) }
  let(:project) { create(:project, depositor: depositor) }
  let(:collection) { create(:collection, project: project, depositor: depositor) }
  let!(:core_file) { create(:core_file, depositor: depositor, collections: [ collection ]) }

  def solr_ids_deleted
    @solr_ids_deleted ||= []
  end

  context 'when records are destroyed' do
    before do
      # The global stub in rails_helper replaces delete_record, so record the calls
      # by id instead. Instance-level stubs would not survive destroy_all's reloaded objects.
      allow_any_instance_of(SolrHelpers).to receive(:delete_record).and_wrap_original do |original|
        record = original.receiver
        solr_ids_deleted << "#{record.class}_#{record.id}"
      end
    end

    it 'removes a core file from Solr when it is destroyed' do
      core_file.destroy

      expect(solr_ids_deleted).to eq([ "CoreFile_#{core_file.id}" ])
    end

    it 'removes a collection from Solr when it is destroyed' do
      collection.destroy

      expect(solr_ids_deleted).to include("Collection_#{collection.id}")
    end

    it 'removes core files left orphaned by a collection destroy' do
      collection.destroy

      expect(solr_ids_deleted).to include("CoreFile_#{core_file.id}")
    end

    it 'removes a project, its collections and its core files from Solr when the project is destroyed' do
      project.destroy

      expect(solr_ids_deleted).to include(
        "Project_#{project.id}", "Collection_#{collection.id}", "CoreFile_#{core_file.id}"
      )
    end
  end

  describe 'SolrHelpers#delete_record' do
    let(:solr) { instance_double(RSolr::Client, delete_by_id: true, commit: true) }

    before { allow_any_instance_of(SolrHelpers).to receive(:solr_connection).and_return(solr) }

    it 'deletes by the id built from class and id, without rebuilding the Solr document' do
      allow_any_instance_of(Project).to receive(:to_solr).and_raise("associations are gone")

      REAL_DELETE_RECORD.bind_call(project)

      expect(solr).to have_received(:delete_by_id).with("Project_#{project.id}")
      expect(solr).to have_received(:commit)
    end

    it 'logs instead of raising when Solr is down, so the database delete is not undone' do
      allow(solr).to receive(:delete_by_id).and_raise(RSolr::Error::ConnectionRefused.new(uri: URI("http://127.0.0.1:8983/solr/tapas-core")))
      allow(Rails.logger).to receive(:error)

      expect { REAL_DELETE_RECORD.bind_call(project) }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(/Project_#{project.id}/)
    end
  end
end
