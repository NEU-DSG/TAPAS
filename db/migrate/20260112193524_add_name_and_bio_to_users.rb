class AddNameAndBioToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :bio, :text
  end
end
