class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :subject, polymorphic: true, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.jsonb :meta, null: false, default: {}

      t.datetime :created_at, null: false
    end
    add_index :activities, [:subject_type, :subject_id, :created_at]
  end
end
