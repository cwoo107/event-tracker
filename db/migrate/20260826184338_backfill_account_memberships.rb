# Step 2 of 4 - see CreateAccountMemberships. Raw SQL rather than the AR
# models, same reasoning as BackfillAccountId: those models keep
# changing after this migration is written and run.
class BackfillAccountMemberships < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO account_memberships (account_id, user_id, role, created_at, updated_at)
      SELECT account_id, id, role, NOW(), NOW() FROM users
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
