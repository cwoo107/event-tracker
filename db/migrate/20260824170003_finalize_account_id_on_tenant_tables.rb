# Step 3 of 3 - see AddAccountIdToTenantTables and BackfillAccountId.
# Locks account_id down to NOT NULL now that every row has one, and
# replaces each config table's old table-wide uniqueness with an
# account-scoped equivalent (a liaison's color, an org's material
# catalog names, assignment rule/risk threshold keys, and scoring
# weight criteria only need to be unique within one account now).
# assignment_settings had no DB-level uniqueness before (it relied on
# an `only_one_row_exists` app-level validation) - a unique index on
# account_id alone is its new "one row per account" guarantee.
class FinalizeAccountIdOnTenantTables < ActiveRecord::Migration[8.1]
  def up
    %i[users events liaisons assignment_rules assignment_settings risk_thresholds scoring_weights material_items].each do |table|
      change_column_null table, :account_id, false
    end

    remove_index :material_items, :name
    remove_index :assignment_rules, :key
    remove_index :risk_thresholds, :key
    remove_index :scoring_weights, :criterion

    add_index :liaisons, [:account_id, :color], unique: true
    add_index :material_items, [:account_id, :name], unique: true
    add_index :assignment_rules, [:account_id, :key], unique: true
    add_index :risk_thresholds, [:account_id, :key], unique: true
    add_index :scoring_weights, [:account_id, :criterion], unique: true

    # add_reference already created a plain (non-unique) index on
    # assignment_settings.account_id - replace it with a unique one
    # rather than adding a second index on the identical column.
    remove_index :assignment_settings, :account_id
    add_index :assignment_settings, :account_id, unique: true
  end

  def down
    remove_index :assignment_settings, :account_id
    add_index :assignment_settings, :account_id
    remove_index :scoring_weights, [:account_id, :criterion]
    remove_index :risk_thresholds, [:account_id, :key]
    remove_index :assignment_rules, [:account_id, :key]
    remove_index :material_items, [:account_id, :name]
    remove_index :liaisons, [:account_id, :color]

    add_index :scoring_weights, :criterion, unique: true
    add_index :risk_thresholds, :key, unique: true
    add_index :assignment_rules, :key, unique: true
    add_index :material_items, :name, unique: true

    %i[users events liaisons assignment_rules assignment_settings risk_thresholds scoring_weights material_items].each do |table|
      change_column_null table, :account_id, true
    end
  end
end
