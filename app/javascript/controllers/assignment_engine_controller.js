import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output", "total"]

  update(event) {
    const index = this.inputTargets.indexOf(event.target)
    if (index !== -1 && this.outputTargets[index]) {
      this.outputTargets[index].textContent = `${event.target.value}%`
    }
    this.recalculateTotal()
  }

  recalculateTotal() {
    const total = this.inputTargets.reduce((sum, input) => sum + Number(input.value), 0)
    if (this.hasTotalTarget) this.totalTarget.textContent = total
  }
}
