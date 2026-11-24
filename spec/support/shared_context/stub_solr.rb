RSpec.configure do |rspec|
  # This config option will be enabled by default on RSpec 4,
  # but for reasons of backwards compatibility, you have to
  # set it on RSpec 3.
  #
  # It causes the host group and examples to inherit metadata
  # from the shared context.
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context 'stub Solr', :shared_context => :metadata do
  before(:each) do
    # Stub Solr to avoid needing a running Solr instance.
    # Project, Collection, and CoreFile all fire after_save Solr callbacks.
    allow_any_instance_of(SolrHelpers).to receive(:index_record).and_return(true)
    allow(SolrHelpers).to receive(:solr_connection).and_return(double("RSolr",
      add: true, commit: true, delete_by_query: true, delete_by_id: true))
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'stub Solr', :include_shared => true
end