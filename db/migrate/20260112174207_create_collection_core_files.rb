class CreateCollectionCoreFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_core_files do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :core_file, null: false, foreign_key: true

      t.timestamps
    end

    add_index :collection_core_files, [:collection_id, :core_file_id], unique: true, name: 'index_collection_core_files_on_collection_and_core_file'
  end
end
