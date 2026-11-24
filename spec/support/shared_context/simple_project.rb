RSpec.configure do |rspec|
  # This config option will be enabled by default on RSpec 4,
  # but for reasons of backwards compatibility, you have to
  # set it on RSpec 3.
  #
  # It causes the host group and examples to inherit metadata
  # from the shared context.
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context 'simple project', :shared_context => :metadata do
  before(:each) do
    # Stub Solr to avoid needing a running Solr instance.
    # Project, Collection, and CoreFile all fire after_save Solr callbacks.
    allow_any_instance_of(SolrHelpers).to receive(:index_record).and_return(true)
    allow(SolrHelpers).to receive(:solr_connection).and_return(double("RSolr",
      add: true, commit: true, delete_by_query: true, delete_by_id: true))
  end

  let!(:is_project_public) { true }
  let!(:depositor) { User.create!(name: 'Dep', email: 'dep@test.com', password: 'pass1234!') }
  # Note: Project.after_create :assign_default_owner auto-creates 1 owner PM for the depositor.
  let!(:project)   { Project.create!(title: 'Test Project', 
                                     depositor_id: depositor.id,
                                     is_public: is_project_public) }
end

# A version that also includes a contributor.
RSpec.shared_context 'simple project with contributor', :shared_context => :metadata do
  include_context 'simple project' do
    let!(:member)    { User.create!(name: 'Member', email: 'member@test.com', password: 'pass1234!') }
    let!(:pm)        { ProjectMember.create!(project_id: project.id, user_id: member.id, role: 'contributor') }
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'simple project', :include_shared => true
  rspec.include_context 'simple project with contributor', :include_shared => true
end