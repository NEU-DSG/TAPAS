class RemoveNeedsAdminVettingFromProjectMembers < ActiveRecord::Migration[8.1]
  def change
    # Vetting now happens at the account level (users.account_status), so a
    # membership-level flag is redundant.
    remove_column :project_members, :needs_admin_vetting, :boolean, null: false, default: false
  end
end
