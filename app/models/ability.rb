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
      can :read, Project, project_members: { user_id: user.id, status: :active }
      can [ :update, :destroy, :manage_members ], Project do |project|
        project.project_members.exists?(user: user, role: "owner", status: :active)
      end

      # Array (pluck) so CanCan can match against instances as well as generate SQL.
      # Only active members receive access — pending members have no project permissions.
      member_project_ids = ProjectMember
        .where(user: user, status: :active)
        .pluck(:project_id)

      can :read, Collection, project_id: member_project_ids if member_project_ids.any?

      can :create, Collection do |collection|
        collection.project&.project_members&.exists?(user: user, role: "owner", status: :active)
      end

      can [ :update, :destroy ], Collection do |collection|
        collection.project.project_members.exists?(user: user, role: "owner", status: :active)
      end

      can :read, CoreFile, collections: { project_id: member_project_ids } if member_project_ids.any?

      can :create, CoreFile

      can :update, CoreFile, collections: { project: { project_members: { user_id: user.id, status: :active } } }

      can :destroy, CoreFile do |core_file|
        core_file.project&.project_members&.exists?(user: user, role: "owner", status: :active)
      end

      # --- ImageFiles ---
      can [ :create, :destroy ], ImageFile do |image_file|
        case image_file.imageable_type
        when "User"
          image_file.imageable_id == user.id
        when "Project"
          image_file.imageable&.project_members&.exists?(user: user, role: "owner", status: :active)
        when "Collection"
          image_file.imageable&.depositor == user ||
            image_file.imageable&.project&.project_members&.exists?(user: user, role: "owner", status: :active)
        when "CoreFile"
          image_file.imageable&.depositor == user ||
            image_file.imageable&.project&.project_members&.exists?(user: user, role: "owner", status: :active)
        end
      end

      # --- CollectionCoreFiles ---
      can [ :create, :destroy ], CollectionCoreFile do |ccf|
        ccf.collection&.project&.project_members&.exists?(user: user, status: :active)
      end

      # --- Users ---
      can [ :edit, :update ], User, id: user.id
    end
  end
end
