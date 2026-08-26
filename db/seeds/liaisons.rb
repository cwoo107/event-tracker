# Coordinator/admin login plus the five real Marketing & Education
# liaisons found in the historical event log (MEEventLog-28.xlsx).
#
# Emails and passwords are placeholders - the source spreadsheet had no
# contact info for these people, only their names. Reset every password
# (and probably the coordinator's name/email) before using this anywhere
# but a local/demo database.
#
# Regions are a nominal best fit from each liaison's most frequent city in
# the log, not a confirmed home base - see db/seeds/historical_events.rb's
# header comment for why that's a real simplification, not just a detail.
#
# Matt Dodd and Collin Miyadi are admins only (no Liaison record). Historical
# events that listed them are created without assigning those two people.

placeholder_password = "changeme12345"

coordinator = User.find_or_create_by!(email_address: "coordinator@usan.org") do |user|
  user.name = "USAN Program Manager"
  user.job_title = "Program Manager"
  user.password = placeholder_password
end
AccountMembership.find_or_create_by!(user: coordinator, account: DEFAULT_ACCOUNT) { |m| m.role = :admin }

# Real field liaisons (role: liaison + Liaison record)
liaison_seed = [
  { slug: "chris_botting", name: "Chris Botting", region: "Central Valley", color: "#2f6fa8" },
  { slug: "dulze_white", name: "Dulze White", region: "East Bay/Delta", color: "#3d8b4c" },
  { slug: "nathan_oliver", name: "Nathan Oliver", region: "South Bay/Peninsula", color: "#7c5ba6" }
].freeze

liaison_seed.each do |attrs|
  email = "#{attrs[:slug].tr('_', '.')}@usan.org"

  user = User.find_or_create_by!(email_address: email) do |u|
    u.name = attrs[:name]
    u.job_title = "Marketing & Education Liaison"
    u.password = placeholder_password
  end
  AccountMembership.find_or_create_by!(user: user, account: DEFAULT_ACCOUNT) { |m| m.role = :liaison }

  Liaison.find_or_create_by!(user: user, account: DEFAULT_ACCOUNT) do |liaison|
    liaison.region = attrs[:region]
    liaison.color = attrs[:color]
  end
end

# Admins who appeared in the historical log but should not be assignable
admin_seed = [
  { slug: "matt_dodd", name: "Matt Dodd" },
  { slug: "collin_miyadi", name: "Collin Miyadi" }
].freeze

admin_seed.each do |attrs|
  email = "#{attrs[:slug].tr('_', '.')}@usan.org"

  user = User.find_or_create_by!(email_address: email) do |u|
    u.name = attrs[:name]
    u.job_title = "Admin"
    u.password = placeholder_password
  end

  membership = AccountMembership.find_or_create_by!(user: user, account: DEFAULT_ACCOUNT) { |m| m.role = :admin }
  membership.update!(role: :admin) unless membership.admin?
end

puts "Seeded #{User.count} users (#{Liaison.count} liaisons) - coordinator: #{coordinator.email_address}"
