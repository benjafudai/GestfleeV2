import { Controller } from "@hotwired/stimulus"

// Renders a bar chart of reported failures (incidents) per month.
export default class extends Controller {
  static values = { labels: Array, counts: Array }

  connect() {
    if (typeof Chart === "undefined") return

    this.chart = new Chart(this.element.getContext("2d"), {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: "Fallas reportadas",
            data: this.countsValue,
            backgroundColor: "rgba(220, 53, 69, 0.55)",
            borderRadius: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { beginAtZero: true, ticks: { precision: 0 } },
        },
        plugins: {
          legend: { display: false },
        },
      },
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
