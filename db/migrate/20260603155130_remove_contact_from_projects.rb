class RemoveContactFromProjects < ActiveRecord::Migration[8.1]
  def change
    remove_column :projects, :contact, :string
  end
end
