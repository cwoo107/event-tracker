import { Controller } from "@hotwired/stimulus"

// Scoped over the sidebar + map together. Clicking a sidebar row or a map
// marker (both carry data-event-id and this same click action) toggles
// .is-active on every matching element in scope, giving instant visual
// feedback while the real navigation - fetching and swapping the detail
// panel - is handled entirely by Turbo, not this controller.
export default class extends Controller {
  select(event) {
    const id = event.currentTarget.dataset.eventId

    this.element.querySelectorAll("[data-event-id]").forEach((el) => {
      el.classList.toggle("is-active", el.dataset.eventId === id)
    })
  }
}
