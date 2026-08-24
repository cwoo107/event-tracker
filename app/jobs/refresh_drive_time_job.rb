# Runs Event#refresh_drive_time! off the request cycle, so a slow Mapbox
# Directions response never holds up the intake form or an edit save.
class RefreshDriveTimeJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    Event.find_by(id: event_id)&.refresh_drive_time!
  end
end
