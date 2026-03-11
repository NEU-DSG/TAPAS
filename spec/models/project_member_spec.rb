# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectMember, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    describe 'uniqueness of user scoped to project' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }

      it 'rejects duplicate user within the same project' do
        create(:project_member, project: project, user: user)
        duplicate = build(:project_member, project: project, user: user)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user]).to be_present
      end

      it 'allows the same user in different projects' do
        other_project = create(:project)
        create(:project_member, project: project, user: user)
        other_membership = build(:project_member, project: other_project, user: user)
        expect(other_membership).to be_valid
      end
    end

    describe 'role inclusion' do
      it 'rejects an invalid role' do
        member = build(:project_member, role: 'invalid_role')
        expect(member).not_to be_valid
        expect(member.errors[:role]).to be_present
      end

      it 'accepts all valid roles' do
        ProjectMember::ROLES.each do |role|
          member = build(:project_member, role: role)
          member.valid?
          expect(member.errors[:role]).to be_empty
        end
      end
    end
  end

  describe 'constants' do
    it 'defines ROLES with contributor and owner' do
      expect(ProjectMember::ROLES).to match_array(%w[contributor owner])
    end
  end
end
