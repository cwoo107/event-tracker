import { Controller } from "@hotwired/stimulus"

// Client-side call to Mapbox's Geocoding API using the same public token
// the map already uses - Mapbox's public tokens are designed to be
// embedded in client-side code, this isn't exposing a secret.
export default class extends Controller {
  static targets = ["query", "latitude", "longitude", "city", "county", "state", "zip", "status"]
  static values = { accessToken: String }

  async locate() {
    const query = this.queryTarget.value.trim()
    if (!query) {
      this.statusTarget.textContent = "Enter an address first."
      return
    }

    this.statusTarget.textContent = "Locating..."

    const url =
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json` +
      `?access_token=${this.accessTokenValue}&country=US&limit=1`

    let feature
    try {
      const response = await fetch(url)
      const data = await response.json()
      feature = data.features && data.features[0]
    } catch (error) {
      this.statusTarget.textContent = "Couldn't reach the geocoder. Check the address and try again."
      return
    }

    if (!feature) {
      this.statusTarget.textContent = "No match found - check the address and try again."
      return
    }

    const [lng, lat] = feature.center
    this.longitudeTarget.value = lng
    this.latitudeTarget.value = lat

    const context = feature.context || []
    const find = (prefix) => context.find((c) => c.id.startsWith(prefix))?.text || ""

    if (this.hasCityTarget) this.cityTarget.value = find("place")
    if (this.hasCountyTarget) this.countyTarget.value = find("district")
    if (this.hasZipTarget) this.zipTarget.value = find("postcode")
    if (this.hasStateTarget) {
      const region = context.find((c) => c.id.startsWith("region"))
      this.stateTarget.value = (region?.short_code || "").replace("US-", "") || this.stateTarget.value
    }

    this.statusTarget.textContent = `Located: ${feature.place_name}`
  }
}
