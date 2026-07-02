class ProjectMember < ApplicationRecord
  # constants
  ROLES = %w[contributor owner]

  # enums
  enum :status, { pending: 0, active: 1 }, default: :active

  # associations
  belongs_to :project
  belongs_to :user

  # validations
  validates :user, uniqueness: { scope: :project, message: "is already a member of
  this project" }
  validates :role, inclusion: { in: ROLES, message: "%{value} is not a valid role" }
  validate :no_active_to_pending_transition, if: :status_changed?

  private

  def no_active_to_pending_transition
    if status_was == "active" && status == "pending"
      errors.add(:status, "cannot transition from active to pending")
    end
  end
end
