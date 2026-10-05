import { Controller } from "@hotwired/stimulus"

// Renders a combined bar (liters) + line (cost) chart for fuel history.
export default class extends Controller {
  static values = { labels: Array, liters: Array, costs: Array }

  connect() {
    if (typeof Chart === "undefined") return

    this.chart = new Chart(this.element.getContext("2d"), {
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            type: "bar",
            label: "Litros",
            data: this.litersValue,
            backgroundColor: "rgba(13, 110, 253, 0.55)",
            borderRadius: 4,
            yAxisID: "y",
          },
          {
            type: "line",
            label: "Costo ($)",
            data: this.costsValue,
            borderColor: "#fd7e14",
            backgroundColor: "rgba(253, 126, 20, 0.15)",
            tension: 0.3,
            yAxisID: "y1",
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        scales: {
          y: {
            type: "linear",
            position: "left",
            title: { display: true, text: "Litros" },
            beginAtZero: true,
          },
          y1: {
            type: "linear",
            position: "right",
            title: { display: true, text: "Costo ($)" },
            beginAtZero: true,
            grid: { drawOnChartArea: false },
          },
        },
      },
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
