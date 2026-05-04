class AddContactAndWebsiteToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :contact, :string
    add_column :projects, :website, :string
  end
end
