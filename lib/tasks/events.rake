namespace :events do
  desc "Backfill drive time/distance/route geometry for every event with a location, via Mapbox"
  task refresh_drive_times: :environment do
    events = Event.where.not(location: nil)
    total = events.count
    not_found = []

    events.find_each.with_index(1) do |event, index|
      event.refresh_drive_time!
      status = event.drive_time_minutes ? "#{event.drive_time_minutes}m / #{event.drive_distance_miles}mi" : "not found"
      not_found << event if event.drive_time_minutes.nil?
      puts "[#{index}/#{total}] ##{event.id} #{event.title.truncate(50)} - #{status}"
    end

    puts "\nDone. #{total - not_found.size}/#{total} updated."
    puts "Mapbox couldn't find a route for: #{not_found.map(&:id).join(', ')}" if not_found.any?
  end
end
