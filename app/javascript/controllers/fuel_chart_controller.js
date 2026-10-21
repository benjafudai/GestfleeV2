import { Controller } from "@hotwired/stimulus"
import { Chart, applyChartTheme, chartColors } from "../lib/chart_theme"

// Renders a combined bar (liters) + line (cost) chart for fuel history.
export default class extends Controller {
  static values = { labels: Array, liters: Array, costs: Array }

  connect() {
    applyChartTheme()
    // On phones the axis titles overlap the tick labels, so hide them and abbreviate amounts.
    const narrow = window.innerWidth < 576
    const compact = new Intl.NumberFormat("es-CL", { notation: "compact", maximumFractionDigits: 1 })

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
          // Labels arrive complete ("Septiembre 2026", shown in the tooltip title); the axis only shows "Sep".
          x: {
            ticks: {
              maxRotation: 0,
              autoSkip: true,
              callback: function (value) { return String(this.getLabelForValue(value)).slice(0, 3) },
            },
          },
          y: {
            type: "linear",
            position: "left",
            title: { display: !narrow, text: "Litros" },
            beginAtZero: true,
          },
          y1: {
            type: "linear",
            position: "right",
            title: { display: !narrow, text: "Costo ($)" },
            ticks: { callback: (value) => "$" + compact.format(value) },
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
