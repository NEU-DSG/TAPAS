# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectMemberCollectionScope, type: :model do
  let(:owner) { create(:user) }
  let(:project) { create(:project, depositor: owner) }
  let(:collection) { create(:collection, project: project, depositor: owner) }
  let(:contributor) { create(:user) }
  let(:contributor_member) { create(:project_member, project: project, user: contributor, role: "contributor") }
  let(:owner_member) { project.project_members.find_by(user: owner, role: "owner") }

  describe "associations" do
    it { is_expected.to belong_to(:project_member) }
    it { is_expected.to belong_to(:collection) }
  end

  describe "validations" do
    it "is valid with a contributor member and a collection" do
      scope = described_class.new(project_member: contributor_member, collection: collection)
      expect(scope).to be_valid
    end

    it "enforces uniqueness of collection scoped to project_member" do
      described_class.create!(project_member: contributor_member, collection: collection)
      duplicate = described_class.new(project_member: contributor_member, collection: collection)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:collection]).to be_present
    end

    it "prevents owners from being scoped" do
      scope = described_class.new(project_member: owner_member, collection: collection)
      expect(scope).not_to be_valid
      expect(scope.errors[:base]).to include("owners cannot be scoped to a specific collection")
    end
  end

  describe "ProjectMember#project_wide?" do
    it "returns true when the member has no collection scopes" do
      expect(contributor_member.project_wide?).to be true
    end

    it "returns false when the member has collection scopes" do
      described_class.create!(project_member: contributor_member, collection: collection)
      expect(contributor_member.project_wide?).to be false
    end
  end

  describe "ProjectMember#scoped_to?" do
    let(:other_collection) { create(:collection, project: project, depositor: owner) }

    it "returns true for a project-wide member regardless of collection" do
      expect(contributor_member.scoped_to?(collection)).to be true
      expect(contributor_member.scoped_to?(other_collection)).to be true
    end

    it "returns true for the allowed collection when scoped" do
      described_class.create!(project_member: contributor_member, collection: collection)
      expect(contributor_member.scoped_to?(collection)).to be true
    end

    it "returns false for a non-allowed collection when scoped" do
      described_class.create!(project_member: contributor_member, collection: collection)
      expect(contributor_member.scoped_to?(other_collection)).to be false
    end
  end
end
