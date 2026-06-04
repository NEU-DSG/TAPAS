# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }

    describe 'email uniqueness' do
      subject { create(:user) }

      it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    end
  end

  describe 'associations' do
    it { is_expected.to have_one(:image_file).dependent(:destroy) }
    it { is_expected.to have_many(:project_members) }
    it { is_expected.to have_many(:projects).through(:project_members) }
  end

  describe '#admin?' do
    context 'when admin_at is set' do
      let(:user) { create(:user, :admin) }

      it 'returns true' do
        expect(user.admin?).to be true
      end
    end

    context 'when admin_at is nil' do
      let(:user) { create(:user) }

      it 'returns false' do
        expect(user.admin?).to be false
      end
    end
  end

  describe '#role_in' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }

    context 'when user is a project owner' do
      before { project } # trigger project creation so the depositor gets assigned as owner

      it 'returns "owner"' do
        expect(depositor.role_in(project)).to eq('owner')
      end
    end

    context 'when user is a contributor' do
      let(:contributor) { create(:user) }

      before do
        create(:project_member, :contributor, project: project, user: contributor)
      end

      it 'returns "contributor"' do
        expect(contributor.role_in(project)).to eq('contributor')
      end
    end

    context 'when user is not a member of the project' do
      let(:non_member) { create(:user) }

      before { project }

      it 'returns nil' do
        expect(non_member.role_in(project)).to be_nil
      end
    end
  end

  describe '#sole_owned_projects' do
    let(:user) { create(:user) }

    it 'returns projects where the user is the only owner' do
      project = create(:project, depositor: user)
      expect(user.sole_owned_projects).to include(project)
    end

    it 'excludes projects where the user is a co-owner' do
      project = create(:project, depositor: user)
      co_owner = create(:user)
      create(:project_member, :owner, project: project, user: co_owner)
      expect(user.sole_owned_projects).not_to include(project)
    end

    it 'excludes projects where the user is only a contributor' do
      depositor = create(:user)
      project = create(:project, depositor: depositor)
      create(:project_member, :contributor, project: project, user: user)
      expect(user.sole_owned_projects).not_to include(project)
    end

    it 'returns an empty collection when the user owns no projects' do
      expect(user.sole_owned_projects).to be_empty
    end
  end

end
