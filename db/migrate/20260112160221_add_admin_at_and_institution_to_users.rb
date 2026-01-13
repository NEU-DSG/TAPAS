class AddAdminAtAndInstitutionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :admin_at, :datetime
    add_column :users, :institution, :string
  end
end
