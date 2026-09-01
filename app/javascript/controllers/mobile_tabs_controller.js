import { Controller } from "@hotwired/stimulus"

// Below the md breakpoint, the map page's two tabs (list / map) can't both
// fit on screen at once, so this shows one at a time. At md and up,
// Tailwind's `md:flex` classes keep both panes visible no matter what this
// toggles, so it has no visible effect on desktop.
export default class extends Controller {
  static targets = ["pane", "tabButton"]

  show(event) {
    this.showTab(event.currentTarget.dataset.tab)
  }

  showMap() {
    this.showTab("map")
  }

  showTab(tab) {
    this.paneTargets.forEach((pane) => pane.classList.toggle("hidden", pane.dataset.tab !== tab))
    this.tabButtonTargets.forEach((button) => {
      const active = button.dataset.tab === tab
      button.classList.toggle("border-brand-700", active)
      button.classList.toggle("text-brand-700", active)
      button.classList.toggle("border-transparent", !active)
      button.classList.toggle("text-slate-500", !active)
    })
  }
}
