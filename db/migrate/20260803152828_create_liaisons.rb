class CreateLiaisons < ActiveRecord::Migration[8.1]
  def change
    create_table :liaisons do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :color, null: false
      # fixed coverage-area taxonomy shown on the Liaisons screen and used
      # to score "regional familiarity" (see Liaison::REGIONS)
      t.string :region, null: false
      t.string :home_city
      # free-text qualifications shown on the liaison profile (e.g. "Spanish
      # bilingual", "CDL-certified rig") - informational only for now, not
      # yet a scoring input
      t.string :skills, array: true, null: false, default: []
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
