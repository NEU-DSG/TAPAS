class AddNeedsAdminVettingToProjectMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :project_members, :needs_admin_vetting, :boolean, null: false, default: false
  end
end
