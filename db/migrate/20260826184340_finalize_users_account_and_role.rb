# Step 4 of 4 - see CreateAccountMemberships, BackfillAccountMemberships,
# AddAccountToSessions. Every user's account/role now lives on
# account_memberships instead.
class FinalizeUsersAccountAndRole < ActiveRecord::Migration[8.1]
  def up
    remove_column :users, :account_id, :bigint
    remove_column :users, :role, :integer, null: false, default: 0
  end

  def down
    add_reference :users, :account, null: true, foreign_key: true
    add_column :users, :role, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE users SET account_id = m.account_id, role = m.role
      FROM (
        SELECT DISTINCT ON (user_id) user_id, account_id, role
        FROM account_memberships ORDER BY user_id, created_at
      ) m
      WHERE users.id = m.user_id
    SQL

    change_column_null :users, :account_id, false
  end
end
