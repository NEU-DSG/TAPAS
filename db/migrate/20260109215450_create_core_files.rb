class CreateCoreFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :core_files do |t|
      t.string "title", null: false
      t.text "description"
      t.boolean "is_public", default: true
      t.integer "depositor_id", null: false
      t.string "ography_type"
      t.text "tei_authors"
      t.text "tei_contributors"
      t.timestamps
    end
  end
end
