import { Controller } from "@hotwired/stimulus"

// Generic toggle-a-panel-on-click dropdown, closing on an outside click
// or Escape - used by the nav's user menu, but not specific to it.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.outsideClickListener = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.outsideClickListener)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickListener)
  }

  toggle() {
    this.panelTarget.classList.toggle("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }
}
