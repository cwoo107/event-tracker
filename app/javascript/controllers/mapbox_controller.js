import { Controller } from "@hotwired/stimulus"

// Markers are real <a> elements with href + data-turbo-frame="event_detail" -
// clicking one is a normal Turbo Frame navigation, not a custom click
// handler that fetches and swaps content. This controller's own JS is only
// for what Turbo genuinely can't do: standing up the Mapbox GL instance,
// keeping the radius-ring overlay aligned as the map pans/zooms, and
// showing/hiding completed markers client-side.
//
// The element this controller is attached to wraps the actual map
// container (data-mapbox-target="canvas") plus the legend and HQ info
// cards, and carries data-turbo-permanent (see _map_canvas.html.erb) so
// Turbo Drive visits triggered by the assign/unassign/reassign actions
// (turbo_frame: "_top") preserve this whole subtree - the live map
// instance, and the completed-events toggle's state - instead of tearing
// it down and reinitializing on every click. Mapbox is only ever given
// the inner canvas target as its container, never this wrapper, so it
// can't see or touch the legend/button siblings.
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    accessToken: String,
    officeLng: Number,
    officeLat: Number,
    events: Array,
    selectedId: String,
    selectedRoute: String
  }

  connect() {
    mapboxgl.accessToken = this.accessTokenValue

    this.map = new mapboxgl.Map({
      container: this.canvasTarget,
      style: "mapbox://styles/mapbox/light-v11",
      center: [this.officeLngValue, this.officeLatValue],
      zoom: 6.3
    })

    this.completedMarkerElements = []
    this.showCompleted = true

    this.map.on("load", () => {
      this.addOfficeMarker()
      this.addEventMarkers()
      this.addRadiusRings()
      this.addRouteLayer()
      this.applyRoute(this.selectedRouteValue)
    })
    this.map.on("move", () => this.positionRadiusRings())

    // The map wrapper is data-turbo-permanent (see _map_canvas.html.erb),
    // so it - and this controller - survive every Turbo navigation
    // untouched; only the event_detail frame actually reloads when a
    // marker or sidebar row is clicked. Listening here, rather than
    // relying on selectedRouteValue, is how the route line stays in sync
    // with whichever event is selected after that first connect().
    this.frameLoadListener = this.handleDetailFrameLoad.bind(this)
    document.addEventListener("turbo:frame-load", this.frameLoadListener)

    // Mapbox sizes its internal canvas to the container's dimensions at
    // construction time and never rechecks on its own. If layout hasn't
    // fully settled yet when connect() runs (web fonts / Tailwind CSS
    // loading can shift timing just enough), the canvas gets stuck at a
    // stale or zero size - no error, just an invisible map. Watching the
    // container and calling resize() whenever it actually changes size
    // fixes both that initial race and any later container resizing.
    this.resizeObserver = new ResizeObserver(() => this.map.resize())
    this.resizeObserver.observe(this.canvasTarget)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    document.removeEventListener("turbo:frame-load", this.frameLoadListener)
    this.map?.remove()
  }

  handleDetailFrameLoad(event) {
    if (event.target.id !== "event_detail") return

    // Turbo Frame navigation only swaps a frame's inner content, never the
    // <turbo-frame> element's own attributes - so the route geometry has
    // to be read off a child element (see map.html.erb), not
    // event.target.dataset directly.
    const holder = event.target.querySelector("[data-route-geometry]")
    this.applyRoute(holder?.dataset.routeGeometry)
  }

  addRouteLayer() {
    this.map.addSource("drive-route", { type: "geojson", data: { type: "FeatureCollection", features: [] } })
    this.map.addLayer({
      id: "drive-route-line",
      type: "line",
      source: "drive-route",
      layout: { "line-join": "round", "line-cap": "round" },
      paint: { "line-color": "#1f4d2b", "line-width": 3, "line-opacity": 0.75 }
    })
  }

  // geometryJson is a GeoJSON LineString geometry, JSON-encoded server-side
  // from Event#drive_route_geometry - or "null" (or blank) when the
  // selected event has none yet, which clears the line.
  applyRoute(geometryJson) {
    const source = this.map.getSource("drive-route")
    if (!source) return

    const geometry = geometryJson ? JSON.parse(geometryJson) : null
    source.setData(
      geometry ? { type: "Feature", geometry, properties: {} } : { type: "FeatureCollection", features: [] }
    )
  }

  // Pure client-side - every event's data is already in eventsValue from
  // the initial page load, so there's nothing to fetch. This deliberately
  // does not touch the sidebar or go through Turbo at all: completed
  // events are still listed there regardless of this toggle, since
  // scrolling past them there isn't the problem this solves.
  toggleCompleted(event) {
    this.showCompleted = !this.showCompleted
    this.completedMarkerElements.forEach((element) => {
      element.style.display = this.showCompleted ? "" : "none"
    })
    event.currentTarget.textContent = this.showCompleted ? "Hide completed" : "Show completed"
  }

  addOfficeMarker() {
    const el = document.createElement("div")
    el.className = "map-marker"
    el.innerHTML = '<div class="dot" style="background:#1f4d2b;width:10px;height:10px;border:2px solid white;"></div>'
    new mapboxgl.Marker({ element: el, anchor: "bottom" })
      .setLngLat([this.officeLngValue, this.officeLatValue])
      .addTo(this.map)
  }

  addEventMarkers() {
    this.eventsValue.forEach((ev) => {
      if (ev.lng == null || ev.lat == null) return

      const link = document.createElement("a")
      link.href = ev.path
      link.dataset.turboFrame = "event_detail"
      link.dataset.eventId = ev.id
      link.dataset.action = "click->selection#select"
      link.className = "map-marker" + (String(ev.id) === this.selectedIdValue ? " is-active" : "")

      const dot = document.createElement("div")
      dot.className = "dot"
      dot.style.background = ev.fill
      dot.style.border = `2px solid ${ev.border}`
      link.appendChild(dot)

      new mapboxgl.Marker({ element: link, anchor: "bottom" })
        .setLngLat([ev.lng, ev.lat])
        .addTo(this.map)

      if (ev.completed) this.completedMarkerElements.push(link)
    })
  }

  // Approximate concentric rings, not true isochrones - minutes converted
  // to a straight-line radius at an assumed ~45mph blended surface/highway
  // speed. Matches the simplified concentric-circle look from the original
  // mockup; a real isochrone would need a routing-service call per liaison,
  // which is out of scope here.
  addRadiusRings() {
    this.ringMiles = [33.75, 67.5, 112.5] // 45 / 90 / 150 minutes @ ~45mph
    this.ringsEl = document.createElement("div")
    this.ringsEl.style.position = "absolute"
    this.ringsEl.style.inset = "0"
    this.ringsEl.style.pointerEvents = "none"
    this.ringsEl.innerHTML = this.ringMiles.map(() => '<div class="radius-ring"></div>').join("")
    this.canvasTarget.appendChild(this.ringsEl)
    this.positionRadiusRings()
  }

  positionRadiusRings() {
    if (!this.ringsEl) return

    const center = this.map.project([this.officeLngValue, this.officeLatValue])
    const milesPerPixel = this.milesPerPixelAtCenter()

    this.ringsEl.querySelectorAll(".radius-ring").forEach((ring, i) => {
      const diameterPx = (this.ringMiles[i] * 2) / milesPerPixel
      ring.style.left = `${center.x}px`
      ring.style.top = `${center.y}px`
      ring.style.width = `${diameterPx}px`
      ring.style.height = `${diameterPx}px`
    })
  }

  // Standard Web Mercator ground-resolution formula, so the rings stay
  // geographically accurate (not just fixed pixel circles) as the map
  // is panned or zoomed.
  milesPerPixelAtCenter() {
    const metersPerPixel =
      (156543.03392 * Math.cos((this.officeLatValue * Math.PI) / 180)) / Math.pow(2, this.map.getZoom())
    return metersPerPixel / 1609.344
  }
}
