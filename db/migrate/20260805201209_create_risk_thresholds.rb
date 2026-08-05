class CreateRiskThresholds < ActiveRecord::Migration[8.1]
  def change
    create_table :risk_thresholds do |t|
      t.string :key, null: false
      t.decimal :multiplier, precision: 5, scale: 2, null: false
      t.boolean :enabled, null: false, default: true
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :risk_thresholds, :key, unique: true
  end
end
