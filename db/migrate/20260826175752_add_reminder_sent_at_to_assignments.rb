class AddReminderSentAtToAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :assignments, :reminder_sent_at, :datetime
  end
end
