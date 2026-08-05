class CreateEventMaterialItems < ActiveRecord::Migration[8.1]
  def change
    create_table :event_material_items do |t|
      t.references :event, null: false, foreign_key: true
      t.references :material_item, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.boolean :checked, null: false, default: false
      t.datetime :checked_at
      t.references :checked_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :event_material_items, [:event_id, :material_item_id],
              unique: true, name: "index_event_material_items_on_event_and_material"
  end
end
