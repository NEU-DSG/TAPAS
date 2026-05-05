# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.admin?
      can :manage, :all
      return
    end

    # --- Projects ---
    can :read, Project, is_public: true

    # --- Collections ---
    can :read, Collection, is_public: true

    # --- CoreFiles ---
    can :read, CoreFile, is_public: true

    if user.persisted?
      can :create, Project
      can :read, Project, project_members: { user_id: user.id }
      can [ :update, :destroy, :manage_members ], Project do |project|
        project.project_members.exists?(user: user, role: "owner")
      end

      # Arrays (pluck) so CanCan can match against instances as well as generate SQL.
      # Project-wide members have no collection scopes; scoped members have at least one.
      project_wide_project_ids = ProjectMember
        .left_joins(:collection_scopes)
        .where(user: user)
        .where(project_member_collection_scopes: { id: nil })
        .pluck(:project_id)

      scoped_collection_ids = ProjectMemberCollectionScope
        .joins(:project_member)
        .where(project_members: { user_id: user.id })
        .pluck(:collection_id)

      # Project-wide members can read any collection in their project.
      # Scoped members can additionally read their explicitly assigned collections.
      can :read, Collection, project_id: project_wide_project_ids if project_wide_project_ids.any?
      can :read, Collection, id: scoped_collection_ids if scoped_collection_ids.any?

      can :create, Collection do |collection|
        collection.project&.project_members&.exists?(user: user, role: "owner")
      end

      can [ :update, :destroy ], Collection do |collection|
        collection.project.project_members.exists?(user: user, role: "owner")
      end

      # Same scoping pattern for CoreFiles.
      can :read, CoreFile, collections: { project_id: project_wide_project_ids } if project_wide_project_ids.any?
      can :read, CoreFile, collections: { id: scoped_collection_ids } if scoped_collection_ids.any?

      can :create, CoreFile

      can :update, CoreFile, collections: { project: { project_members: { user_id: user.id } } }

      can :destroy, CoreFile do |core_file|
        core_file.project&.project_members&.exists?(user: user, role: "owner")
      end

      # --- ImageFiles ---
      can [ :create, :destroy ], ImageFile do |image_file|
        case image_file.imageable_type
        when "User"
          image_file.imageable_id == user.id
        when "Project"
          image_file.imageable&.project_members&.exists?(user: user, role: "owner")
        when "Collection"
          image_file.imageable&.depositor == user ||
            image_file.imageable&.project&.project_members&.exists?(user: user, role: "owner")
        when "CoreFile"
          image_file.imageable&.depositor == user ||
            image_file.imageable&.project&.project_members&.exists?(user: user, role: "owner")
        end
      end

      # --- CollectionCoreFiles ---
      can [ :create, :destroy ], CollectionCoreFile do |ccf|
        ccf.collection&.project&.project_members&.exists?(user: user)
      end

      # --- Users ---
      can [ :edit, :update ], User, id: user.id
    end
  end
end
