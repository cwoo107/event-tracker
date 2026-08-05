class CreateScoringWeights < ActiveRecord::Migration[8.1]
  def change
    create_table :scoring_weights do |t|
      t.string :criterion, null: false
      t.decimal :weight, precision: 5, scale: 2, null: false
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :scoring_weights, :criterion, unique: true
  end
end
