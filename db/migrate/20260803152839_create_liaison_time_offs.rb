class CreateLiaisonTimeOffs < ActiveRecord::Migration[8.1]
  def change
    create_table :liaison_time_offs do |t|
      t.references :liaison, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :reason

      t.timestamps
    end
    add_index :liaison_time_offs, [:liaison_id, :starts_on, :ends_on]
  end
end
