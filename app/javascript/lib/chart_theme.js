// Shared Chart.js look, matching the app theme in gestflee.css.
// Chart is the global loaded from the CDN script in the layout.
export const chartColors = {
  primary: "rgba(31, 111, 209, 0.8)",
  primaryLight: "rgba(31, 111, 209, 0.12)",
  navy: "#0e2240",
}

export function applyChartTheme() {
  Chart.defaults.font.family = "'Lato', 'Segoe UI', system-ui, sans-serif"
  Chart.defaults.color = "#6b7a8f"
  Chart.defaults.borderColor = "#edf1f6"
}
