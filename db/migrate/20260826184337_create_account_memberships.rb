# Step 1 of 4 for letting a User belong to more than one Account: this
# join table replaces users.account_id/users.role (dropped in
# FinalizeUsersAccountAndRole once BackfillAccountMemberships has moved
# every existing user's account + role onto a membership row). Role
# moves here too since it's meaningfully per-account - an admin in one
# account can be a plain coordinator in another.
class CreateAccountMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :account_memberships do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :account_memberships, [:account_id, :user_id], unique: true
  end
end
