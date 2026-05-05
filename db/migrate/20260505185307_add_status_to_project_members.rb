class AddStatusToProjectMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :project_members, :status, :integer, null: false, default: 1
  end
end
