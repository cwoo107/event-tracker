# Step 1 of 3 for replacing Event's fixed event_type enum with an
# account-scoped EventType catalog admins manage themselves - see
# BackfillEventTypeIds and FinalizeEventTypeOnEvents. Nullable at first
# so the backfill can populate it before it's locked down.
class AddEventTypeToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :event_type, null: true, foreign_key: true
  end
end
