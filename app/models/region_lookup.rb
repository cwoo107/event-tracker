# Maps an Event to one of Liaison::REGIONS, for the dashboard's
# "events by region" chart. Deliberately independent of Liaison#region -
# this answers "where did events happen," not "who covers what," and
# keeps working regardless of whether liaisons ever have regions
# assigned again.
#
# Two lookups, tried in order:
#   1. State == "NV" -> always "Nevada", regardless of county name (a
#      handful of California counties share a name with a Nevada one -
#      "Humboldt" is a county in both states - checking state first
#      sidesteps that collision entirely rather than needing state+county
#      compound keys everywhere).
#   2. County, mapped via COUNTY_TO_REGION - the intake form's geocoder
#      populates county for new events, so this is the correct long-term
#      path.
#   3. City, mapped via CITY_TO_REGION - a fallback for events without a
#      county on file, which as of this writing is every event imported
#      from the historical log (that data predates the county field).
#      Not a backfill migration on purpose - this fallback means one
#      isn't needed for the chart to be accurate.
#
# Returns nil (rendered as "Unmapped" by the dashboard) if none of that
# resolves - a real possibility outside the North Cal/Nevada coverage
# area, or for a city not in the fallback list below.
module RegionLookup
  COUNTY_TO_REGION = {
    # North Coast
    "Del Norte" => "North Coast", "Humboldt" => "North Coast", "Mendocino" => "North Coast",
    "Lake" => "North Coast", "Sonoma" => "North Coast", "Marin" => "North Coast",
    # Far North
    "Siskiyou" => "Far North", "Modoc" => "Far North", "Trinity" => "Far North",
    "Shasta" => "Far North", "Lassen" => "Far North", "Tehama" => "Far North",
    "Plumas" => "Far North", "Glenn" => "Far North", "Butte" => "Far North",
    # Sacramento Valley
    "Sacramento" => "Sacramento Valley", "Yolo" => "Sacramento Valley", "Sutter" => "Sacramento Valley",
    "Yuba" => "Sacramento Valley", "Colusa" => "Sacramento Valley", "Placer" => "Sacramento Valley",
    # Sierra/Foothills - "Nevada" here is Nevada COUNTY, California; only
    # ever reached when state != "NV" (see #for below), so no collision
    # with the "Nevada" region despite the same name.
    "Nevada" => "Sierra/Foothills", "El Dorado" => "Sierra/Foothills", "Amador" => "Sierra/Foothills",
    "Calaveras" => "Sierra/Foothills", "Tuolumne" => "Sierra/Foothills", "Alpine" => "Sierra/Foothills",
    "Mono" => "Sierra/Foothills", "Sierra" => "Sierra/Foothills",
    # East Bay/Delta
    "Contra Costa" => "East Bay/Delta", "Alameda" => "East Bay/Delta", "Solano" => "East Bay/Delta",
    "Napa" => "East Bay/Delta",
    # South Bay/Peninsula
    "Santa Clara" => "South Bay/Peninsula", "San Mateo" => "South Bay/Peninsula",
    "San Francisco" => "South Bay/Peninsula", "Santa Cruz" => "South Bay/Peninsula",
    "San Benito" => "South Bay/Peninsula", "Monterey" => "South Bay/Peninsula",
    # Central Valley
    "San Joaquin" => "Central Valley", "Stanislaus" => "Central Valley", "Merced" => "Central Valley",
    "Madera" => "Central Valley", "Fresno" => "Central Valley", "Kings" => "Central Valley",
    "Tulare" => "Central Valley", "Kern" => "Central Valley", "San Luis Obispo" => "Central Valley"
  }.freeze

  CITY_TO_REGION = {
    "American Canyon" => "East Bay/Delta", "Antioch" => "East Bay/Delta", "Auburn" => "Sierra/Foothills",
    "Bakersfield" => "Central Valley", "Berkeley" => "East Bay/Delta", "Brentwood" => "East Bay/Delta",
    "Capay" => "Sacramento Valley", "Chico" => "Far North", "Clovis" => "Central Valley",
    "Coalinga" => "Central Valley", "Colfax" => "Sierra/Foothills", "Concord" => "East Bay/Delta",
    "Cotati" => "North Coast", "Daly City" => "South Bay/Peninsula", "Davis" => "Sacramento Valley",
    "Dixon" => "East Bay/Delta", "Elk Grove" => "Sacramento Valley", "Elko" => "Nevada",
    "Eureka" => "North Coast", "Fairfield" => "East Bay/Delta", "Fresno" => "Central Valley",
    "Livermore" => "East Bay/Delta", "Lodi" => "Central Valley", "Martinez" => "East Bay/Delta",
    "Milpitas" => "South Bay/Peninsula", "Morgan Hill" => "South Bay/Peninsula", "Napa" => "East Bay/Delta",
    "Newark" => "South Bay/Peninsula", "North Las Vegas" => "Nevada", "Oakland" => "East Bay/Delta",
    "Oakley" => "East Bay/Delta", "Palo Alto" => "South Bay/Peninsula", "Pittsburg" => "East Bay/Delta",
    "Pleasanton" => "East Bay/Delta", "Redding" => "Far North", "Reno" => "Nevada",
    "Richmond" => "East Bay/Delta", "Rio Vista" => "East Bay/Delta", "Rohnert Park" => "North Coast",
    "Roseville" => "Sacramento Valley", "Sacramento" => "Sacramento Valley", "Salinas" => "South Bay/Peninsula",
    "San Francisco" => "South Bay/Peninsula", "San Jose" => "South Bay/Peninsula",
    "San Luis Obispo" => "Central Valley", "San Martin" => "South Bay/Peninsula", "San Ramon" => "East Bay/Delta",
    "Sanger" => "Central Valley", "Santa Clara" => "South Bay/Peninsula", "Santa Cruz" => "South Bay/Peninsula",
    "Santa Rosa" => "North Coast", "Stockton" => "Central Valley", "Tulare" => "Central Valley",
    "Turlock" => "Central Valley", "Vacaville" => "East Bay/Delta", "Visalia" => "Central Valley",
    "Winnemucca" => "Nevada", "Woodland" => "Sacramento Valley"
  }.freeze

  def self.for(event)
    return "Nevada" if event.state == "NV"

    COUNTY_TO_REGION[event.county] || CITY_TO_REGION[event.city]
  end
end
