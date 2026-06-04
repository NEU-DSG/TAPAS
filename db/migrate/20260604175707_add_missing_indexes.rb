class AddMissingIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :collections, :project_id
    add_index :core_files, :depositor_id
    add_index :image_files, :depositor_id
    add_index :project_members, [ :user_id, :project_id ], unique: true
  end
end
