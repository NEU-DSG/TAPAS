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
      can [:update, :destroy, :manage_members], Project do |project|
        project.project_members.exists?(user: user, role: "owner")
      end
    end
  end
end
