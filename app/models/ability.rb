# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # User.new is not persisted, so guest users fall through all persisted? guards below
    user ||= User.new

    if user.admin?
      can :manage, :all
      return
    end

    # --- Projects ---
    # Anyone can read public projects
    can :read, Project, is_public: true

    if user.persisted?
      can :create, Project

      # Members (any role) can read projects they belong to.
      # Hash condition (not a block) so accessible_by can translate it to SQL.
      can :read, Project, project_members: { user_id: user.id }

      # Owners can update, destroy, and manage members
      can [ :update, :destroy, :manage_members ], Project do |project|
        project.project_members.exists?(user: user, role: "owner")
      end
    end

    # --- Collections ---
    can :read, Collection, is_public: true

    if user.persisted?
      can :read, Collection, project: { project_members: { user_id: user.id } }

      can :create, Collection do |collection|
        collection.project&.project_members&.exists?(user: user, role: "owner")
      end

      can [ :update, :destroy ], Collection do |collection|
        collection.project.project_members.exists?(user: user, role: "owner")
      end
    end

    # --- CoreFiles ---
    can :read, CoreFile, is_public: true

    if user.persisted?
      can :read, CoreFile, collections: { project: { project_members: { user_id: user.id } } }

      # Fine-grained create authorization (depositor must be project member)
      # is enforced by the model's depositor_is_project_member validation
      can :create, CoreFile

      can :update, CoreFile, collections: { project: { project_members: { user_id: user.id } } }

      # TODO: The spec notes contributors can set configurations for their own records
      # (e.g. default view package), which implies the depositor may have field-level
      # permissions beyond what other members have. Flagged for Strategy Group review
      # before implementing per-field update scoping.
      can :destroy, CoreFile do |core_file|
        core_file.project&.project_members&.exists?(user: user, role: "owner")
      end
    end

    # --- Users ---
    if user.persisted?
      can :update, User, id: user.id
    end
  end
end
