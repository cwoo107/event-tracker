# Step 1 of 3 for making the app multi-tenant: add a nullable account_id
# (with FK, no NOT NULL yet) to every account-scoped table. A data
# migration backfills every existing row to one default Account next
# (see BackfillAccountId), and a follow-up migration then locks the
# column down to NOT NULL and replaces the old global unique indexes
# with account-scoped ones (see AddNotNullAccountIdAndScopeUniqueness).
# Splitting it this way avoids adding a NOT NULL column with no default
# directly on tables that already have rows.
class AddAccountIdToTenantTables < ActiveRecord::Migration[8.1]
  def change
    %i[users events liaisons assignment_rules assignment_settings risk_thresholds scoring_weights material_items].each do |table|
      add_reference table, :account, null: true, foreign_key: true
    end
  end
end
