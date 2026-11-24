require 'rails_helper'
require 'support/shared_context/stub_solr.rb'
require 'support/shared_context/simple_project.rb'

RSpec.describe 'dummy_data_generator rake tasks' do
  include_context 'stub Solr'

  before(:all) do
    Rails.application.load_tasks
  end

  # The rake helper methods (record_image, check_queue_adapter, etc.) are defined
  # on the top-level main object at rake-load time.
  let(:rake_context) { TOPLEVEL_BINDING.eval('self') }

  before(:each) do
    allow(rake_context).to receive(:record_image)
  end

  def stub_env(key, value)
    stub_const('ENV', ENV.to_h.merge(
      key => value.to_s
    ))
  end

  def invoke(task_name)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke
  end

  # Create new non-admin users.
  def create_users_for_testing(total = 10)
    stub_env('num_non_admin_users', total)
    invoke('dummy_data_generator:non_admin_users')
  end

  # Invoke project creation and return the task's newly-created projects.
  def create_projects
    now = Time.current
    invoke('dummy_data_generator:projects')
    Project.where(created_at: now..Time.zone.now.end_of_day)
  end

  # Invoke project member creation and return newly-created project members.
  def create_project_members
    now = Time.current
    invoke('dummy_data_generator:project_members')
    ProjectMember.where(created_at: now..Time.zone.now.end_of_day)
  end

  # Invoke collection creation and return newly-created collections.
  def create_collections
    now = Time.current
    invoke('dummy_data_generator:collections')
    Collection.where(created_at: now..Time.zone.now.end_of_day)
  end

  # ---------------------------------------------------------------------------
  # :admin_user
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:admin_user' do
    before do
      stub_const('ENV', ENV.to_h.merge(
        'DUMMY_ADMIN_EMAIL'    => 'admin@example.com',
        'DUMMY_ADMIN_PASSWORD' => 'password123!'
      ))
    end

    it 'creates one admin user' do
      expect { invoke('dummy_data_generator:admin_user') }
        .to change(User, :count).by(1)
    end

    it 'sets name to Admin and stamps admin_at' do
      invoke('dummy_data_generator:admin_user')
      user = User.find_by(email: 'admin@example.com')
      expect(user.name).to eq('Admin')
      expect(user.admin_at).to be_present
    end
  end

  # ---------------------------------------------------------------------------
  # :debug_non_admin_user
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:debug_non_admin_user' do
    before do
      stub_const('ENV', ENV.to_h.merge(
        'DUMMY_DEBUG_EMAIL'    => 'debug@example.com',
        'DUMMY_DEBUG_PASSWORD' => 'password123!'
      ))
    end

    it 'creates one debug user' do
      expect { invoke('dummy_data_generator:debug_non_admin_user') }
        .to change(User, :count).by(1)
    end

    it 'sets name to Debug and leaves admin_at nil' do
      invoke('dummy_data_generator:debug_non_admin_user')
      user = User.find_by(email: 'debug@example.com')
      expect(user.name).to eq('Debug')
      expect(user.admin_at).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # :non_admin_users  (slow – creates 275 DB records)
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:non_admin_users', :slow do
    context 'by default, without environment variable `num_non_admin_users`' do
      it 'creates 275 users with no admin privileges' do
        expect { invoke('dummy_data_generator:non_admin_users') }
          .to change(User, :count).by(275)
        expect(User.where(admin_at: nil).count).to eq(275)
      end
    end

    context 'when environment variable `num_non_admin_users=100` is specified' do
      it 'creates 100 users with no admin privileges' do
        stub_env('num_non_admin_users', 100)
        expect { invoke('dummy_data_generator:non_admin_users') }
          .to change(User, :count).by(100)
        expect(User.where(admin_at: nil).count).to eq(100)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # :projects
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:projects' do
    # Explicitly set the subject of these specifications/tests as newly-created projects.
    subject(:new_projects) { create_projects }

    context 'when there are no non-admin users to become project depositors' do
      it 'raises a MissingDependencies error' do
        expect { new_projects }.to raise_error(MissingDependencies)
      end
    end

    context 'when there are non-admin users to become project depositors' do
      before(:each) do
        create_users_for_testing
      end

      shared_examples 'projects' do
        it 'creates the first 3 as private projects' do
          expect(new_projects.limit(3).where(is_public: false).count).to eq(3)
        end
  
        it 'creates at least 3 private projects' do
          expect(new_projects.where(is_public: false).count).to be >= 3
        end
  
        it 'reports the number of new private and public projects in standard output' do
          expect { new_projects }.to output(/\d+ private and \d+ public projects/).to_stdout
        end
  
        context 'when run a second time' do
          it 'does not raise errors' do
            expect { new_projects }.not_to raise_error
            expect { create_projects }.not_to raise_error
          end
  
          it 'does not affect previously-created projects' do
            expect { create_projects }.not_to change { new_projects }
          end
        end
      end
  
      context 'by default, without environment variable `num_projects`' do
        it 'creates 45 projects' do
          expect { new_projects }.to change(Project, :count).by(45)
        end
  
        # We can't test for public projects in the other context, because there's a possibility all 5 will
        # be private.
        it 'creates at least 1 public project' do
          expect(new_projects.where(is_public: true).count).to be >= 1
        end
  
        # We can't test for record_image in the other context, because there's a possibility all 5 won't
        # have an image attached.
        it 'calls record_image for at least 1 project' do
          # In order to test this example, we need to invoke the Rake task AFTER stating what we expect of
          # `rake_context`.
          expect(rake_context).to receive(:record_image)
          create_projects
        end
  
        include_examples 'projects'
      end
  
      context 'when the value of environment variable `num_projects` is not an integer' do
        # Set the environment variable to ask for 'nope' new projects.
        before(:each) do
          stub_const('ENV', ENV.to_h.merge(
            'num_projects' => 'nope'
          ))
        end
  
        it 'raises an ArgumentError' do
          expect { new_projects }.to raise_error(ArgumentError)
        end
      end
  
      context 'when environment variable `num_projects=5` is specified' do
        # Set the environment variable to ask for 5 new projects.
        before(:each) do
          stub_env('num_projects', 5)
        end
  
        it 'creates 5 projects' do
          expect { new_projects }.to change(Project, :count).by(5)
        end
  
        include_examples 'projects'
      end
    end
  end

  # ---------------------------------------------------------------------------
  # :project_members
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:project_members' do
    # Explicitly set the subject of these specifications/tests.
    subject(:new_members) { create_project_members }

    # Create a hash where the key is a project ID and the value is the number of new project members.
    let(:members_per_project) { new_members.group(:project_id).count }

    context 'when no projects exist' do
      it 'raises a MissingDependencies error' do
        expect { new_members }.to raise_error(MissingDependencies)
      end
    end

    context 'when projects exist' do
      include_context 'simple project'

      context 'when no users exist' do
        it 'raises a MissingDependencies error' do
          # Delete the depositor now that the project is created, so there is 1 project and 0 users.
          depositor.destroy
          expect { new_members }.to raise_error(MissingDependencies)
        end
      end

      shared_examples 'project members' do
        it 'creates 0 to 17 new project members for every existing project' do
          # Only projects with 1+ new member will be represented in members_per_project...
          expect(members_per_project.values).to all ( be_between(1, 17).inclusive )
          # ...so we test all ProjectMembers too, remembering that with the depositor, there may be up 
          # to 18 total members.
          expect(ProjectMember.group(:project_id).count.values)
            .to all( be_between(1, 18).inclusive )
        end

        it 'creates 0 to 5 new owners per project' do
          expect(Project.all.to_a).to all(satisfy { |p| p.owner.size == 1 })
          new_members
          expect(Project.all.to_a).to all(satisfy { |p| p.owner.size > 0 && p.owner.size <= 6 })
        end

        it 'creates 0 to 12 new contributors per project' do
          expect(Project.all.to_a).to all(satisfy { |p| p.contributors.empty? })
          new_members
          expect(Project.all.to_a)
            .to all(satisfy { |p| p.contributors.empty? || p.contributors.size <= 12 })
        end
      end # shared examples

      context 'when 1 to 17 users exist' do
        it 'warns that there may not be enough users' do
          create_users_for_testing(2)
          expect { new_members }.to output.to_stderr
        end

        include_examples 'project members'
      end

      context 'when at least 18 users exist' do
        before(:each) do
          # Create 17 users (the depositor makes 18).
          create_users_for_testing(17)
          # Create 5 more projects
          stub_env('num_projects', 5)
          @more_projects = create_projects
        end

        it 'does not issue a warning' do
          expect { new_members }.not_to output.to_stderr
        end

        include_examples 'project members'

        it 'reports any new project members for every existing project' do
          project_ids = @more_projects.pluck(:id)
          project_ids.unshift(project.id)
          # The output pattern is "# project members in PROJECT_ID: PROJECT_TITLE:"
          expect { new_members }.to output {
              for pid in project_ids do
                match(/\d+ project members in #{pid}:/)
              end
            }.to_stdout
        end

        it 'creates new project members for most existing projects' do
          # We expect every project to be represented, but there is a low chance that no new project
          # members will be created for a project. We can expect 4 to 6 out of 6 projects will have new
          # members.
          expect(members_per_project.length)
            .to be_between(@more_projects.size - 1, @more_projects.size + 1).inclusive
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # :collections
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:collections' do
    # Explicitly set the subject of these specifications/tests.
    subject(:new_collections) { create_collections }

    context 'when no projects exist' do
      it 'raises a MissingDependencies error' do
        expect { new_collections }.to raise_error(MissingDependencies)
      end
    end

    context 'when a project exists but without users' do
      include_context 'simple project'

      context 'when there are no TAPAS users at all' do
        it 'raises a MissingDependencies error' do
          # Delete the project depositor, so there is 1 project and 0 users.
          depositor.destroy
          expect { new_collections }.to raise_error(MissingDependencies)
        end
      end

      context 'when there are users but a project has no owners' do
        it 'raises a MissingDependencies error' do
          # Create a few more users so the `User.all.empty?` test passes.
          create_users_for_testing(2)
          # Delete the project depositor, so there is 1 project and 0 owners.
          depositor.destroy
          expect { new_collections }.to raise_error(MissingDependencies)
        end
      end
    end

    shared_examples 'collections' do
      it 'creates 0 to 10 collections per project' do
        expect(Project.pluck(:id))
          .to all(satisfy { |pid| 
            expect(new_collections.where(project_id: pid).count)
              .to be_between(0, 10).inclusive
          })
      end

      it 'chooses a project owner as a depositor' do
        for pid in Project.pluck(:id) do
          owners = ProjectMember.where(project_id: pid)
                                .where(role: 'owner').pluck(:user_id)
          for collection in new_collections.where(project_id: pid) do
            expect(owners).to include(collection.depositor_id)
          end
        end
      end

      it 'reports the total number of collections added to a project' do
        expect { new_collections }
          .to output(/Created \d+ collections in (public|private) project \d+/).to_stdout
      end

      it 'reports the number of public and private collections added to a project' do
        expect { new_collections }.to output {
          match(/\d+ private collections/).and
          match(/\d+ public collections/)
        }.to_stdout
      end
    end # shared examples

    context 'when a project with owners exists' do
      include_context 'simple project with contributor'

      context 'and the project is public' do
        include_context 'simple project with contributor'
        include_examples 'collections'

        it 'creates a mix of public and private collections' do
          num_new = new_collections.count
          public_collections = new_collections.where(is_public: true).count
          private_collections = new_collections.where(is_public: false).count
          expect(public_collections).to be_between(0, num_new).inclusive
          expect(private_collections).to be_between(0, num_new).inclusive
        end
      end

      context 'and the project is private' do
        # Modify the shared context to make the simple project private.
        include_context 'simple project with contributor' do
          let!(:is_project_public) { false }
        end

        include_examples 'collections'

        it 'creates no public collections' do
          expect(new_collections.where(is_public: true).count).to eq(0)
        end
      end

      context 'and the task is run twice' do
        include_context 'simple project with contributor'

        before(:each) {
          # Create an initial batch of collections for the project. If the first call doesn't produce 
          # any collections, try again.
          if create_collections.empty?
            create_collections
          end
        }

        it 'does not issue a warning' do
          expect { new_collections }.not_to output.to_stderr
        end

        include_examples 'collections'
      end
    end

    context 'when many projects exist' do
      include_context 'simple project with contributor'

      before(:each) {
        # Create 16 users (in addition to the 2 from the shared context).
        create_users_for_testing(16)
        # Create 5 more projects.
        stub_env('num_projects', 5)
        @more_projects = create_projects
      }

      include_examples 'collections'

      it 'reports new collections for every existing project' do
        project_ids = @more_projects.pluck(:id)
        project_ids.unshift(project.id)
        expect { new_collections }.to output {
          for pid in project_ids do
            match(/Created \d+ collections in (public|private) project #{pid}:/)
          end
        }.to_stdout
      end
    end
  end

  # ---------------------------------------------------------------------------
  # :core_files
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:core_files' do
    before do
      allow(rake_context).to receive(:check_queue_adapter)
      # RAW_TEI_URL may be set in the test environment; override so attach_tei_file
      # uses the locally-generated XML instead of making a real HTTP request.
      stub_const('RAW_TEI_URL', nil)
    end

    context 'when no collections exist' do
      xit 'does not create any core files' do
        expect { invoke('dummy_data_generator:core_files') }
          .not_to change(CoreFile, :count)
      end
    end

    context 'when a collection with project members exists' do
      let!(:depositor)   { User.create!(name: 'Dep', email: 'dep@test.com', password: 'pass1234!') }
      let!(:owner_user)  { User.create!(name: 'Owner', email: 'owner@test.com', password: 'pass1234!') }
      let!(:project)     { Project.create!(title: 'Test Project', depositor_id: depositor.id) }
      let!(:pm)          { ProjectMember.create!(project_id: project.id, user_id: owner_user.id, role: 'owner') }
      let!(:collection)  do
        Collection.create!(
          title:        'Test Collection',
          depositor_id: depositor.id,
          project_id:   project.id,
          is_public:    true
        )
      end

      xit 'creates 5 core files per collection (3 regular + 2 ography)' do
        expect { invoke('dummy_data_generator:core_files') }
          .to change(CoreFile, :count).by(5)
      end

      xit 'creates 3 regular TEI files and 2 ography files' do
        invoke('dummy_data_generator:core_files')
        expect(CoreFile.where(ography_type: nil).count).to eq(3)
        expect(CoreFile.where.not(ography_type: nil).count).to eq(2)
      end

      xit 'attaches a TEI file to each regular core file' do
        invoke('dummy_data_generator:core_files')
        CoreFile.where(ography_type: nil).each do |cf|
          expect(cf.tei_file).to be_attached
        end
      end

      xit 'assigns a valid ography type to each ography file' do
        invoke('dummy_data_generator:core_files')
        CoreFile.where.not(ography_type: nil).each do |cf|
          expect(CoreFile.all_ography_types).to include(cf.ography_type)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # :delete_indexed
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:delete_indexed' do
    it 'delegates to SolrHelpers.delete_all_indexed_records' do
      expect(SolrHelpers).to receive(:delete_all_indexed_records)
      invoke('dummy_data_generator:delete_indexed')
    end
  end
end
