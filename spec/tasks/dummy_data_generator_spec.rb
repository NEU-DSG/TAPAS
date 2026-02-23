require 'rails_helper'

RSpec.describe 'dummy_data_generator rake tasks' do
  before(:all) do
    Rails.application.load_tasks
  end

  # The rake helper methods (record_image, check_queue_adapter, etc.) are defined
  # on the top-level main object at rake-load time.
  let(:rake_context) { TOPLEVEL_BINDING.eval('self') }

  before do
    # Stub Solr to avoid needing a running Solr instance.
    # Project, Collection, and CoreFile all fire after_save/after_update Solr callbacks.
    solr_conn = SolrHelpers::SOLR_CORE_CONNECTION
    allow(solr_conn).to receive(:add)
    allow(solr_conn).to receive(:commit)
    allow(solr_conn).to receive(:update)
    allow(solr_conn).to receive(:delete_by_query)
    allow(solr_conn).to receive(:delete_by_id)
  end

  def invoke(task_name)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke
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
    it 'creates 275 users with no admin privileges' do
      expect { invoke('dummy_data_generator:non_admin_users') }
        .to change(User, :count).by(275)
      expect(User.where(admin_at: nil).count).to eq(275)
    end
  end

  # ---------------------------------------------------------------------------
  # :projects
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:projects' do
    before do
      # Task samples from User.all / User.all.where(admin_at: nil) – needs a user
      User.create!(name: 'Depositor', email: 'dep@test.com', password: 'password123!')
      allow(rake_context).to receive(:record_image)
    end

    it 'creates 25 projects' do
      expect { invoke('dummy_data_generator:projects') }
        .to change(Project, :count).by(25)
    end

    it 'creates exactly 3 private projects' do
      invoke('dummy_data_generator:projects')
      expect(Project.where(is_public: false).count).to eq(3)
    end

    it 'calls record_image once per project' do
      expect(rake_context).to receive(:record_image).exactly(25).times
      invoke('dummy_data_generator:projects')
    end
  end

  # ---------------------------------------------------------------------------
  # :project_members
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:project_members' do
    context 'when no projects exist' do
      it 'does not create any project members' do
        expect { invoke('dummy_data_generator:project_members') }
          .not_to change(ProjectMember, :count)
      end
    end

    context 'when a project and enough non-admin users exist' do
      let!(:depositor) { User.create!(name: 'Dep', email: 'dep@test.com', password: 'pass1234!') }
      # Note: Project.after_create :assign_default_owner auto-creates 1 owner PM for the depositor.
      let!(:project)   { Project.create!(title: 'Test Project', depositor_id: depositor.id) }

      before do
        # create_project_members needs enough unique non-admin users to fill 6 slots
        # (the depositor is already assigned as owner by assign_default_owner, so 7 others
        # gives 7 remaining candidates for the task to use)
        7.times { |i| User.create!(name: "User #{i}", email: "u#{i}@test.com", password: 'pass1234!') }
      end

      it 'adds 6 project members per project (5 contributors + 1 owner)' do
        # Project creation fires assign_default_owner, so 1 PM already exists.
        # The task adds 6 more on top of that.
        expect { invoke('dummy_data_generator:project_members') }
          .to change(ProjectMember, :count).by(6)
      end

      it 'assigns the correct roles to the members it creates' do
        existing_pm_ids = ProjectMember.pluck(:id)
        invoke('dummy_data_generator:project_members')
        task_members = ProjectMember.where(project_id: project.id).where.not(id: existing_pm_ids)
        expect(task_members.where(role: 'contributor').count).to eq(5)
        expect(task_members.where(role: 'owner').count).to eq(1)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # :collections
  # ---------------------------------------------------------------------------
  describe 'dummy_data_generator:collections' do
    context 'when no projects exist' do
      it 'does not create any collections' do
        expect { invoke('dummy_data_generator:collections') }
          .not_to change(Collection, :count)
      end
    end

    context 'when a project with members exists' do
      let!(:depositor) { User.create!(name: 'Dep', email: 'dep@test.com', password: 'pass1234!') }
      let!(:member)    { User.create!(name: 'Member', email: 'member@test.com', password: 'pass1234!') }
      let!(:project)   { Project.create!(title: 'Test Project', depositor_id: depositor.id) }
      let!(:pm)        { ProjectMember.create!(project_id: project.id, user_id: member.id, role: 'contributor') }

      before { allow(rake_context).to receive(:record_image) }

      it 'creates 3 collections per project (2 public + 1 private)' do
        expect { invoke('dummy_data_generator:collections') }
          .to change(Collection, :count).by(3)
      end

      it 'creates 2 public and 1 private collection' do
        invoke('dummy_data_generator:collections')
        expect(Collection.where(is_public: true).count).to eq(2)
        expect(Collection.where(is_public: false).count).to eq(1)
      end

      it 'calls record_image for each public collection' do
        expect(rake_context).to receive(:record_image).exactly(2).times
        invoke('dummy_data_generator:collections')
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
      it 'does not create any core files' do
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

      it 'creates 5 core files per collection (3 regular + 2 ography)' do
        expect { invoke('dummy_data_generator:core_files') }
          .to change(CoreFile, :count).by(5)
      end

      it 'creates 3 regular TEI files and 2 ography files' do
        invoke('dummy_data_generator:core_files')
        expect(CoreFile.where(ography_type: nil).count).to eq(3)
        expect(CoreFile.where.not(ography_type: nil).count).to eq(2)
      end

      it 'attaches a TEI file to each regular core file' do
        invoke('dummy_data_generator:core_files')
        CoreFile.where(ography_type: nil).each do |cf|
          expect(cf.tei_file).to be_attached
        end
      end

      it 'assigns a valid ography type to each ography file' do
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
