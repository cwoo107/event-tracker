class LiaisonMailer < ApplicationMailer
  # Takes the Assignment (not just the event) since that's what actually
  # represents "you've been assigned to this" as a domain event, and gives
  # the view access to how it happened (auto vs. manual) alongside the
  # event details themselves.
  def event_assigned(assignment)
    @assignment = assignment
    @event = Event.includes(event_material_items: :material_item).find(assignment.event_id)
    @liaison = assignment.liaison

    mail subject: "You're assigned: #{@event.title} (#{@event.starts_at.strftime('%a, %b %-d')})",
         to: @liaison.email_address
  end
end
