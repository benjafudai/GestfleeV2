import { Controller } from "@hotwired/stimulus"
import { applyChartTheme, chartColors } from "../lib/chart_theme"

// Renders a combined bar (liters) + line (cost) chart for fuel history.
export default class extends Controller {
  static values = { labels: Array, liters: Array, costs: Array }

  connect() {
    if (typeof Chart === "undefined") return
    applyChartTheme()

    this.chart = new Chart(this.element.getContext("2d"), {
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            type: "bar",
            label: "Litros",
            data: this.litersValue,
            backgroundColor: chartColors.primary,
            borderRadius: 4,
            yAxisID: "y",
          },
          {
            type: "line",
            label: "Costo ($)",
            data: this.costsValue,
            borderColor: chartColors.navy,
            backgroundColor: chartColors.primaryLight,
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
