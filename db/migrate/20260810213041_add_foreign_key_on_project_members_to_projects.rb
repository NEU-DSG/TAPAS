class AddForeignKeyOnProjectMembersToProjects < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :project_members, :projects
  end
end
