class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :liaison, null: false, foreign_key: true
      t.references :assigned_by, foreign_key: { to_table: :users }
      t.integer :assignment_method, null: false, default: 0 # auto
      # accepted/declined - surfaced on the map card ("Auto-assigned ... accepted")
      t.integer :assignment_status, null: false, default: 0 # accepted
      t.decimal :score, precision: 6, scale: 2
      # per-criterion breakdown captured at assignment time, e.g.
      # { "drive_time" => 18.0, "weekly_load_balance" => 30.0 }
      # so the explanation panel and dashboard can show *why*, even after
      # the underlying weights are changed later in Settings.
      t.jsonb :score_breakdown, null: false, default: {}
      # true for the assignment(s) currently in effect for the event; flipped
      # to false (never deleted) when unassigned or reassigned, so history
      # and the score explanation panel survive. Most events have exactly
      # one active assignment; co-staffed events (500+ attendees) have two.
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :assignments, [:event_id, :created_at]
    add_index :assignments, [:event_id, :active]
    add_index :assignments, [:liaison_id, :active]
  end
end
