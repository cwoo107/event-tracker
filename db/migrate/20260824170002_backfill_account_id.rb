# Step 2 of 3 - see AddAccountIdToTenantTables. Creates one default
# Account for the existing organization's data and backfills every
# row across the newly-added account_id columns to point at it. Uses
# raw SQL rather than the app's AR models since those models will keep
# changing after this migration is written and run.
class BackfillAccountId < ActiveRecord::Migration[8.1]
  def up
    account_id = execute(
      "INSERT INTO accounts (name, created_at, updated_at) VALUES ('USAN', NOW(), NOW()) RETURNING id"
    ).first["id"]

    %w[users events liaisons assignment_rules assignment_settings risk_thresholds scoring_weights material_items].each do |table|
      execute "UPDATE #{table} SET account_id = #{account_id} WHERE account_id IS NULL"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
