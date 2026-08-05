class CreateLiaisonLoadHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :liaison_load_holds do |t|
      t.references :liaison, null: false, foreign_key: true
      t.integer :max_drive_minutes
      t.boolean :block_weekends, null: false, default: false
      t.date :ends_on, null: false
      t.string :reason
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :liaison_load_holds, [:liaison_id, :ends_on]
  end
end
