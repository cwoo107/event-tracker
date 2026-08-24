import { Controller } from "@hotwired/stimulus"

// Mapbox Places typeahead: suggestions drop down under the address field
// as you type (debounced), and clicking one is the ONLY way city/county/
// zip/lat/lng get filled in - see _location_picker.html.erb, which
// renders those fields readonly and greyed out (an inline style, cleared
// here rather than toggled as a class - the two have to stay in sync).
// That keeps the coordinates on file always tied to a real geocoded
// place instead of freehand text that was never actually located.
const MIN_QUERY_LENGTH = 3
const DEBOUNCE_MS = 250

export default class extends Controller {
  static targets = ["query", "suggestions", "city", "county", "zip", "state", "latitude", "longitude"]
  static values = { accessToken: String }

  connect() {
    this.features = []
    this.debounceTimer = null
    this.abortController = null
    this.outsideClickListener = (event) => {
      if (!this.element.contains(event.target)) this.closeSuggestions()
    }
    document.addEventListener("click", this.outsideClickListener)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickListener)
    clearTimeout(this.debounceTimer)
    this.abortController?.abort()
  }

  search() {
    clearTimeout(this.debounceTimer)
    const query = this.queryTarget.value.trim()

    if (query.length < MIN_QUERY_LENGTH) {
      this.closeSuggestions()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchSuggestions(query), DEBOUNCE_MS)
  }

  async fetchSuggestions(query) {
    this.abortController?.abort()
    this.abortController = new AbortController()

    const url =
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json` +
      `?access_token=${this.accessTokenValue}&country=US&autocomplete=true&limit=5`

    let data
    try {
      const response = await fetch(url, { signal: this.abortController.signal })
      data = await response.json()
    } catch (error) {
      if (error.name !== "AbortError") this.closeSuggestions()
      return
    }

    this.renderSuggestions(data.features || [])
  }

  renderSuggestions(features) {
    this.features = features
    if (!features.length) {
      this.closeSuggestions()
      return
    }

    this.suggestionsTarget.innerHTML = features
      .map((feature, index) => `
        <button type="button" data-index="${index}" data-action="click->location-picker#select"
                class="block w-full text-left px-3 py-2 text-[13px] text-slate-700 hover:bg-slate-50">
          ${feature.place_name}
        </button>
      `)
      .join("")
    this.suggestionsTarget.classList.remove("hidden")
  }

  select(event) {
    const feature = this.features[event.currentTarget.dataset.index]
    if (!feature) return

    const [lng, lat] = feature.center
    this.queryTarget.value = feature.place_name
    this.latitudeTarget.value = lat
    this.longitudeTarget.value = lng

    const context = feature.context || []
    const find = (prefix) => context.find((c) => c.id.startsWith(prefix))?.text || ""

    if (this.hasCityTarget) this.fill(this.cityTarget, find("place"))
    if (this.hasCountyTarget) this.fill(this.countyTarget, find("district"))
    if (this.hasZipTarget) this.fill(this.zipTarget, find("postcode"))
    if (this.hasStateTarget) {
      const region = context.find((c) => c.id.startsWith("region"))
      this.stateTarget.value = (region?.short_code || "").replace("US-", "") || this.stateTarget.value
    }

    this.closeSuggestions()
  }

  fill(target, value) {
    target.value = value
    target.style.cssText = "" // clear the server-rendered "empty" greyed-out look
  }

  closeSuggestions() {
    this.suggestionsTarget.classList.add("hidden")
    this.suggestionsTarget.innerHTML = ""
  }
}
