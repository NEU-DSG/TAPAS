class CreateProjectMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :project_members do |t|
      t.belongs_to :project
      t.belongs_to :user
      t.string :role, null: false
      t.boolean :is_project_depositor
      t.timestamps
    end
  end
end
