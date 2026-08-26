# Step 3 of 4 - a session now tracks which of the user's accounts is
# currently active (see Current#account and the account switcher), not
# just who's signed in. Backfilled from each session's user's own
# account_id (still present at this point in the migration sequence)
# before FinalizeUsersAccountAndRole removes that column.
class AddAccountToSessions < ActiveRecord::Migration[8.1]
  def up
    add_reference :sessions, :account, null: true, foreign_key: true

    execute <<~SQL
      UPDATE sessions SET account_id = users.account_id
      FROM users WHERE sessions.user_id = users.id
    SQL
  end

  def down
    remove_reference :sessions, :account, foreign_key: true
  end
end
