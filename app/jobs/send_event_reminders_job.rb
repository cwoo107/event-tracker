# Runs daily (see config/recurring.yml) and emails every liaison actively
# assigned to an event starting tomorrow. Assignment#reminder_sent_at
# guards against a double-send if the job is ever run more than once for
# the same day (a manual retrigger, a recurring-task misfire).
class SendEventRemindersJob < ApplicationJob
  queue_as :default

  def perform(reference_date: Date.current)
    Assignment.active.reminder_not_sent
              .joins(:event).merge(Event.where(starts_at: (reference_date + 1.day).all_day))
              .find_each do |assignment|
      LiaisonMailer.event_reminder(assignment).deliver_later
      assignment.update!(reminder_sent_at: Time.current)
    end
  end
end
