import { Controller } from "@hotwired/stimulus"

// Below the md breakpoint, the map's event-detail frame renders as a
// draggable bottom sheet over the map (Apple/Google Maps style) instead of
// its own 380px rail. At md and up this is a no-op - every method bails out
// via isDesktop() and `md:` classes on the target put the sheet back to a
// plain static column, so desktop is untouched.
const SNAP_POINTS = { hidden: 0, peek: 0.14, half: 0.5, expanded: 0.88 }

export default class extends Controller {
  static targets = ["sheet", "handle"]
  static values = { initial: { type: String, default: "hidden" } }

  connect() {
    this.state = this.initialValue
    this.mediaQuery = window.matchMedia("(min-width: 768px)")
    this.onBreakpointChange = () => this.syncBreakpoint()
    this.mediaQuery.addEventListener("change", this.onBreakpointChange)
    this.syncBreakpoint()
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.onBreakpointChange)
  }

  isDesktop() {
    return this.mediaQuery.matches
  }

  syncBreakpoint() {
    if (this.isDesktop()) {
      this.sheetTarget.classList.remove("hidden")
      this.sheetTarget.style.height = ""
      this.sheetTarget.style.transition = ""
    } else {
      this.applyState(this.state)
    }
  }

  // Called after the event_detail turbo-frame loads - shows the sheet at
  // its default height, or hides it entirely when the loaded frame is the
  // empty state (see data-detail-empty in events/_detail_empty.html.erb).
  syncFrame(event) {
    if (this.isDesktop()) return
    const isEmpty = event.currentTarget.querySelector("[data-detail-empty]") !== null
    this.applyState(isEmpty ? "hidden" : "half")
  }

  applyState(state) {
    this.state = state
    if (this.isDesktop()) return

    this.sheetTarget.style.transition = "height 0.2s ease-out"
    if (state === "hidden") {
      this.sheetTarget.classList.add("hidden")
      this.sheetTarget.style.height = ""
    } else {
      this.sheetTarget.classList.remove("hidden")
      this.sheetTarget.style.height = `${SNAP_POINTS[state] * 100}%`
    }
  }

  dragStart(event) {
    if (this.isDesktop()) return
    this.dragging = true
    this.startY = event.clientY
    this.startHeight = this.sheetTarget.getBoundingClientRect().height
    this.containerHeight = this.sheetTarget.parentElement.getBoundingClientRect().height
    this.sheetTarget.style.transition = "none"
    this.handleTarget.setPointerCapture(event.pointerId)
  }

  dragMove(event) {
    if (!this.dragging) return
    const delta = this.startY - event.clientY
    const min = this.containerHeight * SNAP_POINTS.peek
    const max = this.containerHeight * SNAP_POINTS.expanded
    const height = Math.min(Math.max(this.startHeight + delta, min), max)
    this.sheetTarget.style.height = `${height}px`
    event.preventDefault()
  }

  dragEnd(event) {
    if (!this.dragging) return
    this.dragging = false
    this.handleTarget.releasePointerCapture(event.pointerId)

    const ratio = this.sheetTarget.getBoundingClientRect().height / this.containerHeight
    const nearest = Object.keys(SNAP_POINTS)
      .filter((name) => name !== "hidden")
      .reduce((best, name) => (Math.abs(ratio - SNAP_POINTS[name]) < Math.abs(ratio - SNAP_POINTS[best]) ? name : best), "peek")
    this.applyState(nearest)
  }
}
