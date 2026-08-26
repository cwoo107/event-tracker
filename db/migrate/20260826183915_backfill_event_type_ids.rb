# Step 2 of 3 - see AddEventTypeToEvents and FinalizeEventTypeOnEvents.
# Event#event_type was a fixed Rails enum (0-7, defined in
# app/models/event.rb before this migration removed it) shared by every
# account. This gives every existing account its own EventType row for
# each of the 8 historical values, then points every event at the row
# matching its old integer value. The mapping is hardcoded here (rather
# than read off the Event model, which keeps changing) - same reasoning
# as BackfillAccountId.
class BackfillEventTypeIds < ActiveRecord::Migration[8.1]
  LEGACY_EVENT_TYPES = {
    0 => "Direct presentation",
    1 => "Industry tabling",
    2 => "Industry networking",
    3 => "Office visit cold",
    4 => "Public outreach tabling",
    5 => "Safe event",
    6 => "Site visit",
    7 => "Webinar"
  }.freeze

  def up
    account_ids = execute("SELECT id FROM accounts").map { |row| row["id"] }

    account_ids.each do |account_id|
      LEGACY_EVENT_TYPES.each_value do |name|
        execute <<~SQL
          INSERT INTO event_types (account_id, name, active, created_at, updated_at)
          VALUES (#{account_id}, '#{name}', true, NOW(), NOW())
          ON CONFLICT (account_id, name) DO NOTHING
        SQL
      end
    end

    LEGACY_EVENT_TYPES.each do |value, name|
      execute <<~SQL
        UPDATE events
        SET event_type_id = event_types.id
        FROM event_types
        WHERE events.account_id = event_types.account_id
          AND event_types.name = '#{name}'
          AND events.event_type = #{value}
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
