class CollectionCoreFile < ApplicationRecord
  belongs_to :collection
  belongs_to :core_file

  validate :core_file_project_matches_collection_project

  private

  def core_file_project_matches_collection_project
    return unless core_file && collection

    # Get all other collections this core_file belongs to
    existing_collections = core_file.collections.where.not(id: collection.id)

    if existing_collections.any?
      existing_project_ids = existing_collections.pluck(:project_id).uniq
      if existing_project_ids.any? && !existing_project_ids.include?(collection.project_id)
        errors.add(:base, "CoreFile can only belong to collections within the same project (Project ID: #{existing_project_ids.first})")
      end
    end
  end
end
