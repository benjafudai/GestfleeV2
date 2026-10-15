module ExpensesHelper
  SPANISH_MONTHS = %w[
    enero febrero marzo abril mayo junio
    julio agosto septiembre octubre noviembre diciembre
  ].freeze

  # date.strftime("%B") depende del locale del sistema operativo y en este
  # proyecto no hay config/locales/es.yml, así que devuelve el mes en inglés.
  def long_spanish_date(date)
    return "" unless date
    "#{date.day} de #{SPANISH_MONTHS[date.month - 1]}, #{date.year}"
  end

  # ---------- Costos: categorías ----------

  # Ícono y tono de cada categoría de gasto (el texto viene de expense_category_label).
  EXPENSE_CATEGORY_STYLES = {
    "maintenance" => { icon: "bi-tools",        tone: "info" },
    "fuel"        => { icon: "bi-fuel-pump",    tone: "warning" },
    "parts"       => { icon: "bi-gear",         tone: "secondary" },
    "tolls"       => { icon: "bi-signpost-2",   tone: "success" },
    "insurance"   => { icon: "bi-shield-check", tone: "primary" },
    "other"       => { icon: "bi-three-dots",   tone: "light" }
  }.freeze

  # Clases del círculo de ícono y de la barra de proporción según el tono.
  EXPENSE_TONE_CIRCLES = {
    "info"      => "bg-info-subtle text-info-emphasis",
    "warning"   => "bg-warning-subtle text-warning-emphasis",
    "secondary" => "bg-secondary-subtle text-secondary-emphasis",
    "dark"      => "bg-dark-subtle text-dark-emphasis",
    "primary"   => "bg-primary-subtle text-primary-emphasis",
    "success"   => "bg-success-subtle text-success-emphasis",
    "danger"    => "bg-danger-subtle text-danger-emphasis",
    "light"     => "bg-secondary-subtle text-secondary-emphasis"
  }.freeze

  EXPENSE_TONE_BARS = {
    "info"      => "bg-info",
    "warning"   => "bg-warning",
    "secondary" => "bg-secondary",
    "dark"      => "bg-dark",
    "primary"   => "bg-primary",
    "success"   => "bg-success",
    "danger"    => "bg-danger",
    "light"     => "bg-secondary bg-opacity-50"
  }.freeze

  def expense_category_style(category)
    EXPENSE_CATEGORY_STYLES.fetch(category.to_s, EXPENSE_CATEGORY_STYLES["other"])
  end

  # Píldora de la categoría con su ícono: "⛽ Combustible".
  def expense_category_badge(category)
    style = expense_category_style(category)
    tag.span(class: "badge text-bg-#{style[:tone]}") do
      safe_join([tag.i(class: "bi #{style[:icon]} me-1", "aria-hidden": true), expense_category_label(category)])
    end
  end

  # Círculo de color con un ícono (mismo lenguaje que las tarjetas del dashboard).
  def expense_icon_circle(icon, tone = "primary", **options)
    classes = ["gf-action-icon", EXPENSE_TONE_CIRCLES.fetch(tone.to_s, EXPENSE_TONE_CIRCLES["primary"]), options.delete(:class)]
    tag.span(tag.i(class: "bi #{icon}"), class: classes.compact.join(" "), "aria-hidden": true, **options)
  end

  def expense_category_icon_circle(category, **options)
    style = expense_category_style(category)
    expense_icon_circle(style[:icon], style[:tone], **options)
  end

  def expense_category_bar_class(category)
    EXPENSE_TONE_BARS.fetch(expense_category_style(category)[:tone], "bg-secondary")
  end

  # Total por categoría en CLP (los gastos en USD se convierten), de mayor a menor.
  # Devuelve [[categoría, total_clp], ...] solo con las categorías que tienen gastos.
  def expense_totals_by_category(scope)
    sums = scope.unscope(:order, :includes).group(:category, :currency).sum(:amount)
    totals = Hash.new(0)
    sums.each { |(category, currency), amount| totals[category.to_s] += converted_to_clp(amount, currency) }
    totals.select { |_, total| total.positive? }.sort_by { |_, total| -total }
  end

  # Suma de un conjunto de gastos en CLP (los gastos en USD se convierten).
  def expense_total_in_clp(scope)
    scope.unscope(:order, :includes).group(:currency).sum(:amount)
         .sum { |currency, amount| converted_to_clp(amount, currency) }
  end

  # ---------- Costos: formulario ----------

  # Monto para el campo numérico: sin ".0" sobrante y vacío en un gasto nuevo (muestra el placeholder).
  def expense_amount_field_value(expense)
    amount = expense.amount
    return nil if amount.nil? || (expense.new_record? && amount.zero? && expense.errors[:amount].none?)

    number_with_precision(amount, precision: 2, strip_insignificant_zeros: true, separator: ".", delimiter: "")
  end

  # "RJKT-42 — Toyota Hilux 2.4 4x4"
  def expense_vehicle_option_label(vehicle)
    [vehicle.plate, [vehicle.brand, vehicle.model].compact_blank.join(" ").presence].compact.join(" — ")
  end

  # ---------- Análisis de fallas ----------

  # Mismo color de gravedad que en Incidentes: de azul (baja) a rojo (alta / crítica).
  FAILURE_SEVERITY_TONES = {
    "low"      => "info",
    "medium"   => "warning",
    "high"     => "danger",
    "critical" => "danger"
  }.freeze

  # De menor a mayor gravedad (baja, media, alta, crítica).
  def failure_severity_sorted(counts)
    counts.sort_by { |severity, _| FAILURE_SEVERITY_TONES.keys.index(severity.to_s) || FAILURE_SEVERITY_TONES.size }
  end

  def failure_severity_badge(severity, count)
    tone = FAILURE_SEVERITY_TONES.fetch(severity.to_s, "secondary")
    tag.span("#{incident_severity_label(severity)}: #{count}", class: "badge text-bg-#{tone}")
  end

  # 24.0 → "24,0 h"; nil → "—"
  def failure_hours(hours)
    return "—" if hours.nil?

    "#{number_with_precision(hours, precision: 1, separator: ',', delimiter: '.')} h"
  end

  def expense_percent(value)
    "#{number_with_precision(value.to_f, precision: 1, strip_insignificant_zeros: true, separator: ',', delimiter: '.')}%"
  end

  def failure_count_label(count)
    count == 1 ? "1 falla" : "#{count} fallas"
  end

  def corrective_count_label(count)
    count == 1 ? "1 OT correctiva" : "#{count} OT correctivas"
  end

  # "Mayo 2026" → "May" (etiquetas cortas para que el gráfico no las incline en el celular).
  def failure_chart_short_label(label)
    month, year = label.to_s.split(" ", 2)
    year ? month.to_s[0, 3] : label
  end
end
