# Step 3 of 3 - see AddEventTypeToEvents and BackfillEventTypeIds. Locks
# event_type_id down to NOT NULL now that every row has one, and drops
# the old fixed enum column and its index.
class FinalizeEventTypeOnEvents < ActiveRecord::Migration[8.1]
  def up
    change_column_null :events, :event_type_id, false
    remove_index :events, :event_type
    remove_column :events, :event_type
  end

  def down
    add_column :events, :event_type, :integer, null: false, default: 0
    add_index :events, :event_type
    change_column_null :events, :event_type_id, true
  end
end
