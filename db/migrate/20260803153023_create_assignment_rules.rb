class CreateAssignmentRules < ActiveRecord::Migration[8.1]
  def change
    create_table :assignment_rules do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: true
      # numeric threshold where the rule needs one (event count, hours,
      # miles, attendee count, or minutes-since-midnight for a time bound);
      # units are documented per key on the model.
      t.decimal :threshold, precision: 8, scale: 2
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :assignment_rules, :key, unique: true
  end
end
