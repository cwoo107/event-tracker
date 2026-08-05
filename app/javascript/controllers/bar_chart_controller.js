import { Controller } from "@hotwired/stimulus"

// The controller's own element must be a <canvas> - Chart.js draws
// directly onto it, it isn't a wrapper/target situation like the map.
// Chart.js is loaded as a plain global script in the layout (see
// mapbox_controller.js's comment for why that matters), not an ESM import.
export default class extends Controller {
  static values = {
    labels: Array,
    values: Array,
    colors: Array
  }

  connect() {
    this.chart = new Chart(this.element, {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            data: this.valuesValue,
            backgroundColor: this.hasColorsValue ? this.colorsValue : "#2f7a3e",
            borderRadius: 4,
            maxBarThickness: 28
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { displayColors: false }
        },
        scales: {
          y: { beginAtZero: true, ticks: { precision: 0 } },
          x: { grid: { display: false } }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
