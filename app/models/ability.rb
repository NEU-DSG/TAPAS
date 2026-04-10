# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
      return
    end

    # --- Projects ---
    # Anyone can read public projects
    can :read, Project, is_public: true

    if user.persisted?
      can :create, Project

      # Members (any role) can read projects they belong to
      can :read, Project do |project|
        project.project_members.exists?(user: user)
      end

      # Owners can update, destroy, and manage members
      can [ :update, :destroy, :manage_members ], Project do |project|
        project.project_members.exists?(user: user, role: "owner")
      end
    end

    # --- Collections ---
    can :read, Collection, is_public: true

    if user.persisted?
      can :read, Collection do |collection|
        collection.project.project_members.exists?(user: user)
      end

      can :create, Collection do |collection|
        collection.project&.project_members&.exists?(user: user)
      end

      can [ :update, :destroy ], Collection do |collection|
        collection.depositor == user ||
          collection.project.project_members.exists?(user: user, role: "owner")
      end
    end

    # --- CoreFiles ---
    can :read, CoreFile, is_public: true

    if user.persisted?
      can :read, CoreFile do |core_file|
        project = core_file.project
        project&.project_members&.exists?(user: user)
      end

      # Fine-grained create authorization (depositor must be project member)
      # is enforced by the model's depositor_is_project_member validation
      can :create, CoreFile

      can [ :update, :destroy ], CoreFile do |core_file|
        project = core_file.project
        core_file.depositor == user ||
          project&.project_members&.exists?(user: user, role: "owner")
      end
    end

    # --- Users ---
    if user.persisted?
      can [ :edit, :update ], User, id: user.id
    end
  end
end
