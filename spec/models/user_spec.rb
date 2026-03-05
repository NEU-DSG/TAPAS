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

  describe '#role' do
    let(:depositor) { create(:user) }
    let(:project) { create(:project, depositor: depositor) }

    context 'when user is a project owner' do
      before { project } # trigger project creation so the depositor gets assigned as owner

      it 'returns the role from project_members' do
        expect(depositor.role).to eq('owner')
      end
    end

    context 'when user is a contributor' do
      let(:contributor) { create(:user) }

      before do
        create(:project_member, :contributor, project: project, user: contributor)
      end

      it 'returns contributor' do
        expect(contributor.role).to eq('contributor')
      end
    end
  end

  describe 'devise modules' do
    it 'is database authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'is registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'is recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'is rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'is validatable' do
      expect(User.devise_modules).to include(:validatable)
    end

    it 'is trackable' do
      expect(User.devise_modules).to include(:trackable)
    end
  end
end
