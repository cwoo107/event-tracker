# Imports the historical events from db/seed_data/events.csv and
# db/seed_data/event_materials.csv - cleaned/mapped from the real event
# log (MEEventLog-28.xlsx) you provided. Run db/seeds/liaisons.rb first,
# after DEFAULT_ACCOUNT has been seeded with its material catalog
# (db/seeds.rb does this in order).
#
# A few things worth knowing about this import, since they're judgment
# calls made on your behalf rather than things the source data actually
# said:
#
# - The spreadsheet only has a Date, not a start/end time. Every imported
#   event is given a synthetic 09:00-11:00 window - there's no way to
#   recover the real one from what's in the log.
# - "Requester" doesn't have a real equivalent here - these were
#   self-initiated field visits, not inbound requests. requester_name is
#   the literal placeholder "Field-logged activity"; requester_organization
#   holds the event's actual name/company so that context isn't lost.
# - Drive distance/time are only populated for the 8 rows that had real
#   mileage logged (halved from round-trip to one-way, then time estimated
#   at the same ~45mph assumption the map's radius rings use, for
#   consistency with that existing approximation). The other 123 events
#   have neither - they show as "not yet calculated" in the UI, which is
#   accurate: we don't have that data, so nothing was invented for it.
# - Liaisons' regions (see db/seeds/liaisons.rb) are a nominal best fit
#   from each person's most frequent city, not a confirmed home base -
#   Chris Botting, Dulze White, and Nathan Oliver each worked well outside
#   any single region in the actual log. That's a real mismatch worth
#   knowing about between the schema's one-region-per-liaison assumption
#   and how this team actually seems to operate (broadly, not siloed) -
#   flagging it here rather than letting the seed quietly paper over it.
# - Every imported event is marked completed (assign_to! then complete!),
#   since every logged row is in the past relative to today and the
#   source's Status column is uniformly "Confirmed".
# - Matt Dodd and Collin Miyadi are seeded as admins (no Liaison record),
#   so events that listed them as primary/secondary are imported without
#   assigning those two people.
# - Re-running this script skips events already imported (matched on
#   title + start time) rather than duplicating them - but that's a weak
#   key, not a real uniqueness guarantee. If you need a clean re-import,
#   clear the events table first.

require "csv"

events_csv = Rails.root.join("db/seed_data/events.csv")
materials_csv = Rails.root.join("db/seed_data/event_materials.csv")

unless File.exist?(events_csv)
  puts "No db/seed_data/events.csv found - skipping historical import."
  return
end

coordinator = User.find_by!(email_address: "coordinator@usan.org")
liaisons_by_slug = DEFAULT_ACCOUNT.liaisons.includes(:user).index_by { |liaison| liaison.user.email_address.split("@").first.tr(".", "_") }
materials_by_name = DEFAULT_ACCOUNT.material_items.index_by(&:name)

materials_by_reference = Hash.new { |hash, key| hash[key] = [] }
CSV.foreach(materials_csv, headers: true) do |row|
  materials_by_reference[row["reference"]] << [row["material"], row["quantity"].to_i]
end

imported = 0
skipped = 0

CSV.foreach(events_csv, headers: true) do |row|
  starts_at = Time.zone.parse("#{row['date']} 09:00")
  ends_at = starts_at + 2.hours

  if DEFAULT_ACCOUNT.events.exists?(title: row["title"], starts_at: starts_at)
    skipped += 1
    next
  end

  event = DEFAULT_ACCOUNT.events.create!(
    title: row["title"],
    event_type: row["event_type"],
    source: :manual,
    starts_at: starts_at,
    ends_at: ends_at,
    prep_minutes: 30,
    teardown_minutes: 30,
    venue_name: row["venue_name"].presence,
    city: row["city"],
    state: row["state"],
    latitude: row["latitude"].to_f,
    longitude: row["longitude"].to_f,
    estimated_attendees: row["estimated_attendees"].presence&.to_i,
    overnight_approved: row["overnight_approved"] == "true",
    drive_distance_meters: row["drive_distance_meters"].presence&.to_i,
    drive_time_seconds: row["drive_time_seconds"].presence&.to_i,
    requester_name: "Field-logged activity",
    requester_organization: row["title"],
    requester_email: "fieldlog@usanmarketing.org"
  )

  primary_slug = row["primary_liaison"]
  primary_liaison = liaisons_by_slug[primary_slug]

  if primary_liaison
    event.assign_to!(primary_liaison, by: coordinator, assignment_method: :manual)
  end

  if row["secondary_liaison"].present?
    secondary_liaison = liaisons_by_slug[row["secondary_liaison"]]
    if secondary_liaison
      event.assign_to!(secondary_liaison, by: coordinator, assignment_method: :manual)
    end
  end

  event.complete!(by: coordinator)

  materials_by_reference[row["reference"]].each do |material_name, quantity|
    material = materials_by_name[material_name]
    next unless material

    event.event_material_items.create!(
      material_item: material, quantity: quantity, checked: true,
      checked_by: coordinator, checked_at: event.starts_at
    )
  end

  if row["notes"].present? && primary_liaison
    event.notes.create!(author: primary_liaison.user, body: row["notes"])
  elsif row["notes"].present?
    event.notes.create!(author: coordinator, body: row["notes"])
  end

  imported += 1
end

puts "Imported #{imported} historical events (#{skipped} already present, skipped)."

# Backfills real drive time/distance/route for every event via a live
# Mapbox call, synchronously - not something seeding does by default
# (see Event#refresh_drive_time!'s comment on why seeding normally
# bypasses this entirely), but worth it here so the map has a real
# route line to show for the demo data instead of only the 8 events
# that had mileage in the original spreadsheet. Safe to re-run: a
# failed/rejected lookup for a given event just leaves it as "not yet
# calculated," same as if this block didn't run at all.
total = DEFAULT_ACCOUNT.events.count
puts "Fetching drive time/route from Mapbox for all #{total} events - this makes real API calls and takes a few minutes..."
with_route = 0
DEFAULT_ACCOUNT.events.find_each.with_index(1) do |event, index|
  event.refresh_drive_time!
  with_route += 1 if event.drive_route_geometry.present?
  print "\r  #{index}/#{total} (#{with_route} with a route so far)"
end
puts "\nGot a route for #{with_route} of #{total} events."