class CreateProjectMemberCollectionScopes < ActiveRecord::Migration[8.1]
  def change
    create_table :project_member_collection_scopes do |t|
      t.references :project_member, null: false, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.timestamps
    end
    add_index :project_member_collection_scopes,
              [ :project_member_id, :collection_id ],
              unique: true,
              name: "index_pmcs_on_project_member_and_collection"
  end
end
