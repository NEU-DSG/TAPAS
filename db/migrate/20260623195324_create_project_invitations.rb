class CreateProjectInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :project_invitations do |t|
      t.references :project, null: false, foreign_key: true
      t.bigint :created_by_user_id, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :project_invitations, :created_by_user_id
    add_index :project_invitations, :token, unique: true
    add_foreign_key :project_invitations, :users, column: :created_by_user_id
  end
end
