class ProjectMemberCollectionScope < ApplicationRecord
  belongs_to :project_member
  belongs_to :collection

  validates :collection, uniqueness: { scope: :project_member }
  validate :owner_cannot_be_scoped

  private

  def owner_cannot_be_scoped
    return unless project_member&.role == "owner"
    errors.add(:base, "owners cannot be scoped to a specific collection")
  end
end
