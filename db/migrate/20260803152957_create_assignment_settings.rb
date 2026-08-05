class CreateAssignmentSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :assignment_settings do |t|
      t.integer :work_weeks_per_year, null: false, default: 46
      t.integer :weekly_target, null: false, default: 2
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
