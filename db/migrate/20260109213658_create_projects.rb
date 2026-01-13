class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string "title", null: false
      t.text "description"
      t.integer "depositor_id", null: false
      t.boolean "is_public", default: true
      t.string "institution"
      t.timestamps

      t.index [ "depositor_id" ], name: "index_projects_on_depositor_id"
    end
  end
end
