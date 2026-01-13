class CreateCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :collections do |t|
      t.string "title", null: false
      t.text "description"
      t.integer "project_id", null: false
      t.boolean "is_public"
      t.integer "depositor_id", null: false
      t.timestamps
    end
  end
end
