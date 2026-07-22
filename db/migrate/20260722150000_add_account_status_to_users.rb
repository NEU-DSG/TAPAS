class AddAccountStatusToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :account_status, :integer, null: false, default: 0
    add_column :users, :signup_invitation_token, :string

    # Accounts that existed before account-level vetting are grandfathered in
    # as active; only registrations from here on start blocked.
    execute "UPDATE users SET account_status = 1"
  end

  def down
    remove_column :users, :account_status
    remove_column :users, :signup_invitation_token
  end
end
