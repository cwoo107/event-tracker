class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.integer :event_type, null: false
      t.integer :status, null: false, default: 0 # unassigned
      # public_form: pulled from the public request form
      # member_portal: submitted by a member/requester through their portal
      # manual: entered directly by staff (including "email -> manual" intake)
      t.integer :source, null: false, default: 2 # manual

      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :prep_minutes, null: false, default: 30
      t.integer :teardown_minutes, null: false, default: 30

      # geography (not geometry) so ST_DWithin/ST_Distance return real-world
      # meters without needing a projection step - the simplest correct
      # choice for a statewide-plus-Nevada coverage area.
      t.st_point :location, geographic: true, srid: 4326, null: false
      t.string :address
      t.string :city
      t.string :county
      t.string :state, default: "CA"
      t.string :zip
      t.string :venue_name

      t.string :requester_name, null: false
      t.string :requester_email, null: false
      t.string :requester_phone
      t.string :requester_organization

      t.integer :estimated_attendees
      t.string :audience

      # cached one-way drive time/distance from the office, computed via the
      # Mapbox Directions API when the event is geocoded. Nullable until then.
      t.integer :drive_distance_meters
      t.integer :drive_time_seconds

      # set (by a coordinator) when a same-day round trip exceeds the
      # "block same-day round trips over 3h each way" hard rule threshold,
      # per the Settings screen's hard-rule checklist
      t.boolean :overnight_approved, null: false, default: false

      # NOTE: no liaison_id here - an event's current liaison(s) come from
      # its active assignments, since events over 500 attendees require two.

      t.timestamps
    end

    add_index :events, :location, using: :gist
    add_index :events, :status
    add_index :events, :event_type
    add_index :events, :starts_at
    add_index :events, :county
  end
end
