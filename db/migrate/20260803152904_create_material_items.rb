class CreateMaterialItems < ActiveRecord::Migration[8.1]
  def change
    create_table :material_items do |t|
      t.string :name, null: false
      t.string :category
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :material_items, :name, unique: true
  end
end
