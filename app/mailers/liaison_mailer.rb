class LiaisonMailer < ApplicationMailer
  # Takes the Assignment (not just the event) since that's what actually
  # represents "you've been assigned to this" as a domain event, and gives
  # the view access to how it happened (auto vs. manual) alongside the
  # event details themselves.
  def event_assigned(assignment)
    @assignment = assignment
    @event = Event.includes(event_material_items: :material_item).find(assignment.event_id)
    @liaison = assignment.liaison
    @account = @event.account

    mail subject: "You're assigned: #{@event.title} (#{@event.starts_at.strftime('%a, %b %-d')})",
         to: @liaison.email_address, from: branded_from(@account)
  end

  # Sent by SendEventRemindersJob the day before an event a liaison is
  # actively assigned to. Takes the Assignment for the same reason
  # #event_assigned does - it's the record of "you, specifically" being on
  # the hook for this event, and it's what the job marks as reminded
  # (Assignment#reminder_sent_at) so a rerun never double-sends.
  def event_reminder(assignment)
    @assignment = assignment
    @event = Event.includes(event_material_items: :material_item).find(assignment.event_id)
    @liaison = assignment.liaison
    @account = @event.account

    mail subject: "Reminder: #{@event.title} is tomorrow (#{@event.starts_at.strftime('%a, %b %-d')})",
         to: @liaison.email_address, from: branded_from(@account)
  end
end
