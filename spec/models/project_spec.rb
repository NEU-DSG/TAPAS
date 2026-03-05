# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:depositor_id) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('User') }
    it { is_expected.to have_one(:image_file) }
    it { is_expected.to have_many(:collections) }
    it { is_expected.to have_many(:core_files).through(:collections) }
    it { is_expected.to have_many(:project_members) }
    it { is_expected.to have_many(:users).through(:project_members) }
  end

  describe '#project_group' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:owner_user) { create(:user) }
    let(:contributor_user) { create(:user) }

    before do
      create(:project_member, :owner, project: project, user: owner_user)
      create(:project_member, :contributor, project: project, user: contributor_user)
    end

    it 'returns project members grouped by role' do
      grouped = project.project_group
      expect(grouped.keys).to match_array(%w[owner contributor])
    end

    it 'includes the correct members in each role group' do
      grouped = project.project_group
      expect(grouped["owner"].map(&:user)).to include(owner_user)
      expect(grouped["contributor"].map(&:user)).to include(contributor_user)
    end
  end

  describe '#members' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:owner_user) { create(:user) }
    let(:contributor_user) { create(:user) }

    before do
      create(:project_member, :owner, project: project, user: owner_user)
      create(:project_member, :contributor, project: project, user: contributor_user)
    end

    it 'returns a hash of roles to user arrays' do
      result = project.members
      expect(result).to be_a(Hash)
      expect(result["owner"]).to include(owner_user)
      expect(result["contributor"]).to include(contributor_user)
    end

    it 'includes depositor as default owner when no other members exist' do
      project_with_default = create(:project, depositor: depositor)
      expect(project_with_default.members).to be_a(Hash)
      expect(project_with_default.members["owner"]).to include(depositor)
    end
  end

  describe '#owner' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:owner_user) { create(:user) }

    before do
      create(:project_member, :owner, project: project, user: owner_user)
    end

    it 'returns the owner users' do
      expect(project.owner).to include(owner_user)
    end

    it 'returns the depositor as default owner when no other members exist' do
      project_with_default = create(:project, depositor: depositor)
      expect(project_with_default.owner).to include(depositor)
    end
  end

  describe '#contributors' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }
    let(:contributor_user) { create(:user) }

    before do
      create(:project_member, :contributor, project: project, user: contributor_user)
    end

    it 'returns the contributor users' do
      expect(project.contributors).to include(contributor_user)
    end

    it 'returns nil when there are no contributors' do
      empty_project = create(:project, depositor: depositor)
      expect(empty_project.contributors).to be_nil
    end
  end

  describe '#assign_default_owner' do
    let(:depositor) { create(:user) }

    it 'creates a project member with owner role for the depositor on create' do
      project = create(:project, depositor: depositor)
      expect(project.project_members.count).to eq(1)

      member = project.project_members.first
      expect(member.user).to eq(depositor)
      expect(member.role).to eq("owner")
      expect(member.is_project_depositor).to be true
    end

    it 'does not create a duplicate owner if one already exists' do
      project = create(:project, depositor: depositor)
      expect(project.project_members.where(role: "owner").count).to eq(1)
    end
  end

  describe '#to_solr' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor, title: 'Solr Test Project', is_public: true) }

    it 'returns a complete solr document with depositor as default owner' do
      doc = project.to_solr
      expect(doc["active_record_model_ssi"]).to eq("Project")
      expect(doc["depositor_tesim"]).to eq(depositor.id)
      expect(doc["table_id_ssi"]).to eq(project.id)
      expect(doc["id"]).to eq("Project_#{project.id}")
      expect(doc["edit_access_person_ssim"]).to eq(depositor.id)
      expect(doc["title_info_title_ssi"]).to eq("Solr Test Project")
      expect(doc["access_ssim"]).to eq("public")
      expect(doc["image_file_ssi"]).to eq("public/assets/logo_no_text.png")
    end

    context 'when project is private' do
      let(:private_project) { create(:project, depositor: depositor, is_public: false) }

      it 'sets access to private' do
        doc = private_project.to_solr
        expect(doc["access_ssim"]).to eq("private")
      end
    end
  end
end
