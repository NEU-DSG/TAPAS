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
        member = collection.project.project_members.find_by(user: user)
        member&.scoped_to?(collection)
      end

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
      can :read, CoreFile do |core_file|
        project = core_file.project
        member = project&.project_members&.find_by(user: user)
        next false unless member
        member.project_wide? || core_file.collections.any? { |c| member.collection_scopes.exists?(collection: c) }
      end

      # Fine-grained create authorization (depositor must be project member)
      # is enforced by the model's depositor_is_project_member validation
      can :create, CoreFile

      can :update, CoreFile do |core_file|
        core_file.project&.project_members&.exists?(user: user)
      end

      can :destroy, CoreFile do |core_file|
        core_file.project&.project_members&.exists?(user: user, role: "owner")
      end
    end

    # --- ImageFiles ---
    if user.persisted?
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
    end

    # --- CollectionCoreFiles ---
    if user.persisted?
      can [ :create, :destroy ], CollectionCoreFile do |ccf|
        ccf.collection&.project&.project_members&.exists?(user: user)
      end
    end

    # --- Users ---
    if user.persisted?
      can [ :edit, :update ], User, id: user.id
    end
  end
end
