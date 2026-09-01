import { Controller } from "@hotwired/stimulus"

// The map's "Liaison key" overlay card. Collapsed by default on mobile
// (where it would otherwise cover a chunk of a small map), expanded by
// default on desktop - matching whatever the md breakpoint says at connect
// time, then a plain manual toggle after that.
export default class extends Controller {
  static targets = ["content", "chevron"]

  connect() {
    this.setOpen(window.matchMedia("(min-width: 768px)").matches)
  }

  toggle() {
    this.setOpen(this.contentTarget.classList.contains("hidden"))
  }

  setOpen(open) {
    this.contentTarget.classList.toggle("hidden", !open)
    this.chevronTarget.classList.toggle("rotate-180", !open)
  }
}
