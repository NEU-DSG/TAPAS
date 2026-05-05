class ProjectMember < ApplicationRecord
  # constants
  ROLES = %w[contributor owner]

  # associations
  belongs_to :project
  belongs_to :user
  has_many :collection_scopes, class_name: "ProjectMemberCollectionScope", dependent: :destroy

  # validations
  validates :user, uniqueness: { scope: :project }
  validates :role, inclusion: { in: ROLES, message: "%{value} is not a valid role" }

  def project_wide?
    collection_scopes.none?
  end

  def scoped_to?(collection)
    project_wide? || collection_scopes.exists?(collection: collection)
  end
end
