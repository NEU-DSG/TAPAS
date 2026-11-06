require 'rails_helper'

RSpec.describe 'solr rake tasks' do
  before(:all) do
    Rails.application.load_tasks
  end

  # A double, never a real connection: solr:reindex empties the whole index first.
  let(:connection) do
    double("RSolr", add: true, commit: true, delete_by_query: true, delete_by_id: true, optimize: true)
  end

  before do
    # Creating a Project, Collection or CoreFile fires after_save Solr callbacks.
    allow_any_instance_of(SolrHelpers).to receive(:index_record).and_return(true)
    allow(SolrHelpers).to receive(:solr_connection).and_return(connection)
    allow(STDIN).to receive(:gets)
  end

  def invoke(task_name)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke
  end

  describe 'solr:optimize' do
    it 'optimizes the index' do
      expect(connection).to receive(:optimize)

      expect { invoke('solr:optimize') }.to output(/Done/).to_stdout
    end
  end

  describe 'solr:reindex' do
    let!(:collection) { create(:collection) }
    let(:project)     { collection.project }

    it 'clears the index, re-adds every record, then commits and optimizes' do
      expect(connection).to receive(:delete_by_query).with("*:*").ordered
      expect(connection).to receive(:add).at_least(:once).ordered
      expect(connection).to receive(:optimize).ordered

      expect { invoke('solr:reindex') }.to output(/Reindex complete/).to_stdout
    end

    it 'indexes each project and collection' do
      expect(connection).to receive(:add).with(hash_including("id" => project.to_solr["id"]))
      expect(connection).to receive(:add).with(hash_including("id" => collection.to_solr["id"]))

      expect { invoke('solr:reindex') }.to output.to_stdout
    end

    it 'reports records that fail to index and exits non-zero' do
      allow(connection).to receive(:add).and_raise(StandardError, "solr is down")

      expect { invoke('solr:reindex') }
        .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        .and output(/solr is down/).to_stdout
    end
  end
end
