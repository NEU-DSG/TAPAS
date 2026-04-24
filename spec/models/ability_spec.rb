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

    # Contributors cannot create, update, or destroy collections — owners only
    it { is_expected.not_to be_able_to(:create, Collection.new(project: public_project)) }
    it { is_expected.not_to be_able_to(:update, own_collection) }
    it { is_expected.not_to be_able_to(:destroy, own_collection) }
    it { is_expected.not_to be_able_to(:update, public_collection) }
    it { is_expected.not_to be_able_to(:destroy, public_collection) }

    # CoreFiles — can read all core files in member project (public and private)
    it { is_expected.to be_able_to(:read, public_core_file) }
    it { is_expected.to be_able_to(:read, private_core_file) }

    # Contributors can update any core file in their project; cannot destroy (owners only)
    it { is_expected.to be_able_to(:update, own_core_file) }
    it { is_expected.to be_able_to(:update, public_core_file) }
    it { is_expected.not_to be_able_to(:destroy, own_core_file) }
    it { is_expected.not_to be_able_to(:destroy, public_core_file) }
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
  end

  context "as an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to be_able_to(:manage, :all) }
    it { is_expected.to be_able_to(:manage, public_project) }
    it { is_expected.to be_able_to(:manage, public_collection) }
    it { is_expected.to be_able_to(:manage, public_core_file) }
    it { is_expected.to be_able_to(:manage, owner) }
  end
end
