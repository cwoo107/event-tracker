# The full promotional-materials catalog from the event log's form -
# including items with zero recorded usage in this particular date range
# (Dip Trips, Field Guides - Nevada, Pop Sockets, Rally Towels, Water
# Bottles), since a catalog represents what's available to hand out, not
# just what happened to get used.

material_names = [
  "811 Sticker (2.5)", "811 Sticker (6)", "811 Sticker (9)", "Chip Clips",
  "Color Code Magnets", "Color Code Stickers", "Dip Trips",
  "Field Guides - California", "Field Guides - Nevada", "Keychains", "Koozies",
  "Manuals - California", "Manuals - Nevada", "Pop Sockets", "Rally Towels",
  "Slap Bracelets", "Stress Balls - Soccer", "Sunglasses", "Water Bottles"
].freeze

material_names.each do |name|
  MaterialItem.find_or_create_by!(name: name) { |material| material.category = "Promotional" }
end

puts "Seeded #{MaterialItem.count} material items."
