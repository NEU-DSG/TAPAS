# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

RSpec.describe Ability, type: :model do
  subject(:ability) { Ability.new(user) }

  # Primary project and its resources (all deposited by `owner`)
  let(:owner) { create(:user) }
  let(:public_project) { create(:project, depositor: owner, is_public: true) }
  let(:private_project) { create(:project, depositor: owner, is_public: false) }
  let(:public_collection) { create(:collection, project: public_project, depositor: owner, is_public: true) }
  let(:private_collection) { create(:collection, project: public_project, depositor: owner, is_public: false) }
  let(:public_core_file) { create(:core_file, depositor: owner, collections: [ public_collection ], is_public: true) }
  let(:private_core_file) { create(:core_file, depositor: owner, collections: [ public_collection ], is_public: false) }

  # A separate project owned by someone else
  let(:other_owner) { create(:user) }
  let(:other_project) { create(:project, depositor: other_owner, is_public: false) }

  # ImageFile helpers — build unsaved records with imageable set so ability block can inspect imageable_type
  def user_image_file(for_user)
    build(:image_file, imageable: for_user, depositor: for_user)
  end

  def project_image_file(for_project)
    build(:image_file, imageable: for_project, depositor: for_project.depositor)
  end

  def collection_image_file(for_collection)
    build(:image_file, imageable: for_collection, depositor: for_collection.depositor)
  end

  def core_file_image_file(for_core_file)
    build(:image_file, imageable: for_core_file, depositor: for_core_file.depositor)
  end

  context "as a guest" do
    let(:user) { nil }

    # Projects
    it { is_expected.to be_able_to(:read, public_project) }
    it { is_expected.not_to be_able_to(:read, private_project) }
    it { is_expected.not_to be_able_to(:create, Project.new) }
    it { is_expected.not_to be_able_to(:update, public_project) }
    it { is_expected.not_to be_able_to(:destroy, public_project) }
    it { is_expected.not_to be_able_to(:manage_members, public_project) }

    # Collections
    it { is_expected.to be_able_to(:read, public_collection) }
    it { is_expected.not_to be_able_to(:read, private_collection) }
    it { is_expected.not_to be_able_to(:create, Collection.new(project: public_project)) }
    it { is_expected.not_to be_able_to(:update, public_collection) }
    it { is_expected.not_to be_able_to(:destroy, public_collection) }

    # CoreFiles
    it { is_expected.to be_able_to(:read, public_core_file) }
    it { is_expected.not_to be_able_to(:read, private_core_file) }
    it { is_expected.not_to be_able_to(:create, CoreFile.new) }
    it { is_expected.not_to be_able_to(:update, public_core_file) }
    it { is_expected.not_to be_able_to(:destroy, public_core_file) }

    # Users
    it { is_expected.not_to be_able_to(:edit, owner) }
    it { is_expected.not_to be_able_to(:update, owner) }

    # ImageFiles — guests cannot manage any
    it { is_expected.not_to be_able_to(:create, user_image_file(owner)) }
    it { is_expected.not_to be_able_to(:destroy, user_image_file(owner)) }
  end

  context "as a logged-in non-member" do
    let(:user) { create(:user) }

    # Projects
    it { is_expected.to be_able_to(:read, public_project) }
    it { is_expected.not_to be_able_to(:read, private_project) }
    it { is_expected.to be_able_to(:create, Project.new) }
    it { is_expected.not_to be_able_to(:update, public_project) }
    it { is_expected.not_to be_able_to(:destroy, public_project) }
    it { is_expected.not_to be_able_to(:manage_members, public_project) }

    # Collections
    it { is_expected.to be_able_to(:read, public_collection) }
    it { is_expected.not_to be_able_to(:read, private_collection) }
    it { is_expected.not_to be_able_to(:create, Collection.new(project: public_project)) }
    it { is_expected.not_to be_able_to(:update, public_collection) }
    it { is_expected.not_to be_able_to(:destroy, public_collection) }

    # CoreFiles — ability permits create; model's depositor_is_project_member validates membership
    it { is_expected.to be_able_to(:read, public_core_file) }
    it { is_expected.not_to be_able_to(:read, private_core_file) }
    it { is_expected.to be_able_to(:create, CoreFile.new) }
    it { is_expected.not_to be_able_to(:update, public_core_file) }
    it { is_expected.not_to be_able_to(:destroy, public_core_file) }

    # Users — can only edit own profile
    it { is_expected.to be_able_to(:edit, user) }
    it { is_expected.to be_able_to(:update, user) }
    it { is_expected.not_to be_able_to(:edit, owner) }
    it { is_expected.not_to be_able_to(:update, owner) }

    # ImageFiles — can manage own avatar; cannot manage others' resources
    it { is_expected.to be_able_to(:create, user_image_file(user)) }
    it { is_expected.to be_able_to(:destroy, user_image_file(user)) }
    it { is_expected.not_to be_able_to(:create, user_image_file(owner)) }
    it { is_expected.not_to be_able_to(:create, project_image_file(public_project)) }
    it { is_expected.not_to be_able_to(:create, collection_image_file(public_collection)) }
    it { is_expected.not_to be_able_to(:create, core_file_image_file(public_core_file)) }
  end

  context "as a project contributor" do
    let(:user) { create(:user) }
    let(:own_collection) { create(:collection, project: public_project, depositor: user, is_public: true) }
    let(:own_core_file) { create(:core_file, depositor: user, collections: [ public_collection ]) }

    before { create(:project_member, project: public_project, user: user, role: "contributor") }

    # Projects — member project readable; cannot manage
    it { is_expected.to be_able_to(:read, public_project) }
    it { is_expected.not_to be_able_to(:read, other_project) }
    it { is_expected.not_to be_able_to(:update, public_project) }
    it { is_expected.not_to be_able_to(:destroy, public_project) }
    it { is_expected.not_to be_able_to(:manage_members, public_project) }

    # Collections — can read all collections in member project (public and private)
    it { is_expected.to be_able_to(:read, public_collection) }
    it { is_expected.to be_able_to(:read, private_collection) }
    it { is_expected.to be_able_to(:create, Collection.new(project: public_project)) }
    it { is_expected.not_to be_able_to(:create, Collection.new(project: other_project)) }

    # Can update/destroy own deposited collections; not others'
    it { is_expected.to be_able_to(:update, own_collection) }
    it { is_expected.to be_able_to(:destroy, own_collection) }
    it { is_expected.not_to be_able_to(:update, public_collection) }
    it { is_expected.not_to be_able_to(:destroy, public_collection) }

    # CoreFiles — can read all core files in member project (public and private)
    it { is_expected.to be_able_to(:read, public_core_file) }
    it { is_expected.to be_able_to(:read, private_core_file) }

    # Can update/destroy own deposited core files; not others'
    it { is_expected.to be_able_to(:update, own_core_file) }
    it { is_expected.to be_able_to(:destroy, own_core_file) }
    it { is_expected.not_to be_able_to(:update, public_core_file) }
    it { is_expected.not_to be_able_to(:destroy, public_core_file) }
  end

  context "as a collection-scoped contributor" do
    let(:user) { create(:user) }
    let(:allowed_collection) { public_collection }
    let(:off_limits_collection) { create(:collection, project: public_project, depositor: owner, is_public: false) }
    let(:off_limits_core_file) { create(:core_file, depositor: owner, collections: [ off_limits_collection ], is_public: false) }

    before do
      member = create(:project_member, project: public_project, user: user, role: "contributor")
      create(:project_member_collection_scope, project_member: member, collection: allowed_collection)
    end

    # Collections — can read allowed collection; cannot read others in same project
    it { is_expected.to be_able_to(:read, allowed_collection) }
    it { is_expected.not_to be_able_to(:read, off_limits_collection) }

    # Cannot create new collections — scoped contributors are not project-wide
    it { is_expected.not_to be_able_to(:create, Collection.new(project: public_project)) }

    # CoreFiles — can read files in allowed collection; not files in off-limits collections
    it { is_expected.to be_able_to(:read, public_core_file) }
    it { is_expected.not_to be_able_to(:read, off_limits_core_file) }
  end

  context "as a project owner" do
    let(:user) { owner }

    # Projects — own projects fully manageable
    it { is_expected.to be_able_to(:read, public_project) }
    it { is_expected.to be_able_to(:read, private_project) }
    it { is_expected.to be_able_to(:update, public_project) }
    it { is_expected.to be_able_to(:destroy, public_project) }
    it { is_expected.to be_able_to(:manage_members, public_project) }

    # Projects — other user's projects not manageable
    it { is_expected.not_to be_able_to(:update, other_project) }
    it { is_expected.not_to be_able_to(:destroy, other_project) }
    it { is_expected.not_to be_able_to(:manage_members, other_project) }

    # Collections — full access within own project
    it { is_expected.to be_able_to(:read, public_collection) }
    it { is_expected.to be_able_to(:read, private_collection) }
    it { is_expected.to be_able_to(:create, Collection.new(project: public_project)) }
    it { is_expected.to be_able_to(:update, public_collection) }
    it { is_expected.to be_able_to(:destroy, public_collection) }
    it { is_expected.to be_able_to(:update, private_collection) }

    # CoreFiles — full access within own project
    it { is_expected.to be_able_to(:read, public_core_file) }
    it { is_expected.to be_able_to(:read, private_core_file) }
    it { is_expected.to be_able_to(:update, public_core_file) }
    it { is_expected.to be_able_to(:destroy, public_core_file) }

    # Users — own profile only
    it { is_expected.to be_able_to(:edit, owner) }
    it { is_expected.to be_able_to(:update, owner) }
    it { is_expected.not_to be_able_to(:edit, other_owner) }
    it { is_expected.not_to be_able_to(:update, other_owner) }

    # ImageFiles — own avatar, own project/collection/core_file thumbnails
    it { is_expected.to be_able_to(:create, user_image_file(owner)) }
    it { is_expected.to be_able_to(:destroy, user_image_file(owner)) }
    it { is_expected.to be_able_to(:create, project_image_file(public_project)) }
    it { is_expected.to be_able_to(:destroy, project_image_file(public_project)) }
    it { is_expected.to be_able_to(:create, collection_image_file(public_collection)) }
    it { is_expected.to be_able_to(:destroy, collection_image_file(public_collection)) }
    it { is_expected.to be_able_to(:create, core_file_image_file(public_core_file)) }
    it { is_expected.to be_able_to(:destroy, core_file_image_file(public_core_file)) }
    it { is_expected.not_to be_able_to(:create, project_image_file(other_project)) }
    it { is_expected.not_to be_able_to(:destroy, project_image_file(other_project)) }
  end

  context "as an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to be_able_to(:manage, :all) }
    it { is_expected.to be_able_to(:manage, public_project) }
    it { is_expected.to be_able_to(:manage, public_collection) }
    it { is_expected.to be_able_to(:manage, public_core_file) }
    it { is_expected.to be_able_to(:manage, owner) }
  end

  # accessible_by scope tests — only hash-condition rules translate to SQL.
  # Block-based rules (used for member/owner checks) cannot be converted and are
  # not used with accessible_by in the app; controllers use custom scoping helpers.
  describe "accessible_by scopes" do
    before do
      public_project
      private_project
      public_collection
      private_collection
      public_core_file
      private_core_file
    end

    context "as a guest" do
      let(:user) { nil }

      it "returns only public projects" do
        expect(Project.accessible_by(ability)).to contain_exactly(public_project)
      end

      it "returns only public collections" do
        expect(Collection.accessible_by(ability)).to contain_exactly(public_collection)
      end

      it "returns only public core files" do
        expect(CoreFile.accessible_by(ability)).to contain_exactly(public_core_file)
      end
    end
  end

  # ProjectMember authorization note:
  # There are no direct CanCanCan rules for ProjectMember create/read/update/destroy.
  # ProjectMember management is authorized via the parent Project's :manage_members
  # permission, checked in ProjectMembersController with:
  #   authorize! :manage_members, @project
  # This means admins and project owners can manage members; all others cannot.
end
