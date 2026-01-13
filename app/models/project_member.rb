class ProjectMember < ApplicationRecord
  # constants
  ROLES = %w[contributor owner]

  # associations
  belongs_to :project
  belongs_to :user

  # validations
  validates :user, uniqueness: { scope: :project }
  validates :role, inclusion: { in: ROLES, message: "%{value} is not a valid role" }
end
