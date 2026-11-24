require 'support/shared_context/stub_solr.rb'

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
  include_context 'stub Solr'

  let!(:is_project_public) { true }
  let!(:depositor) { User.create!(name: 'Dep', email: 'dep@test.com', password: 'pass1234!') }
  # Note: Project.after_create :assign_default_owner auto-creates 1 owner PM for the depositor.
  let!(:project)   { Project.create!(title: 'Test Project', 
                                     depositor_id: depositor.id,
                                     is_public: is_project_public) }
end

# A version that also includes a second project member, a contributor.
RSpec.shared_context 'simple project with contributor', :shared_context => :metadata do
  include_context 'simple project' do
    let!(:second_user)    { User.create!(name: 'Member', email: 'member@test.com', password: 'pass1234!') }
    let!(:project_member) { ProjectMember.create!(project_id: project.id, user_id: second_user.id, role: 'contributor') }
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'simple project', :include_shared => true
  rspec.include_context 'simple project with contributor', :include_shared => true
end