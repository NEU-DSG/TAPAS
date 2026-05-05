class ProjectMember < ApplicationRecord
  # constants
  ROLES = %w[contributor owner]

  # enums
  enum :status, { pending: 0, active: 1 }, default: :active

  # associations
  belongs_to :project
  belongs_to :user
  has_many :collection_scopes, class_name: "ProjectMemberCollectionScope", dependent: :destroy

  # validations
  validates :user, uniqueness: { scope: :project }
  validates :role, inclusion: { in: ROLES, message: "%{value} is not a valid role" }
  validate :no_active_to_pending_transition, if: :status_changed?

  def project_wide?
    collection_scopes.none?
  end

  def scoped_to?(collection)
    project_wide? || collection_scopes.exists?(collection: collection)
  end

  private

  def no_active_to_pending_transition
    if status_was == "active" && status == "pending"
      errors.add(:status, "cannot transition from active to pending")
    end
  end
end
