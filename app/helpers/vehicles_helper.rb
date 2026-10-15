module VehiclesHelper
  # "Mercedes-Benz Sprinter 515" (marca y modelo, lo que exista); nil si no hay ninguno.
  def vehicle_name(vehicle)
    [vehicle.brand, vehicle.model].compact_blank.join(" ").presence
  end

  # "133.700 km"; nil si no se ha registrado el odómetro.
  def vehicle_odometer(vehicle)
    "#{number_with_delimiter(vehicle.odometer)} km" if vehicle.odometer.present?
  end

  # "1.250 h"; nil si el vehículo no usa horómetro.
  def vehicle_hour_meter(vehicle)
    "#{number_with_delimiter(vehicle.hour_meter)} h" if vehicle.hour_meter.present?
  end

  # El valor, o un guion suave cuando falta el dato.
  def vehicle_value_or_dash(value)
    value.presence || tag.span("—", class: "text-muted")
  end

  def vehicle_status_badge(vehicle, **options)
    return tag.span("—", class: "text-muted") if vehicle.status.blank?

    status_badge(vehicle_status_label(vehicle.status), vehicle.status, **options)
  end

  # Opciones del selector de estado, con la etiqueta en español.
  def vehicle_status_options
    Vehicle.statuses.keys.map { |status| [vehicle_status_label(status), status] }
  end

  # Cantidad de vehículos por estado, para las tarjetas del listado.
  def vehicle_fleet_summary(scope = Vehicle.all)
    counts = scope.group(:status).count
    {
      total: counts.values.sum,
      active: counts["active"].to_i,
      maintenance: counts["maintenance"].to_i,
      inactive: counts["inactive"].to_i
    }
  end

  # Ícono en círculo para las tarjetas de resumen: grande desde 576px y compacto en celular.
  def vehicle_kpi_icon(icon, tone = "primary")
    safe_join([
      tag.span(tag.i(class: "bi #{icon}"), class: "gf-action-icon bg-#{tone}-subtle text-#{tone}-emphasis d-none d-sm-grid", "aria-hidden": true),
      tag.span(tag.i(class: "bi #{icon}"), class: "d-inline-flex d-sm-none flex-shrink-0 rounded-circle bg-#{tone}-subtle text-#{tone}-emphasis lh-1 p-2", "aria-hidden": true)
    ])
  end

  # Título de tarjeta con su ícono en un círculo suave.
  def vehicle_card_title(title, icon:, tone: "primary", count: nil)
    circle = tag.span(tag.i(class: "bi #{icon}"),
                      class: "d-inline-flex align-items-center justify-content-center flex-shrink-0 rounded-circle " \
                             "bg-#{tone}-subtle text-#{tone}-emphasis lh-1 p-2",
                      "aria-hidden": true)
    parts = [circle, title]
    parts << tag.span(count, class: "badge text-bg-light") unless count.nil?
    tag.h2(safe_join(parts), class: "h6 mb-0 d-flex align-items-center gap-2")
  end

  # Identificación estándar del vehículo en los subtítulos: [camión] HYPC-35 · Mercedes-Benz Sprinter 515.
  # extra: datos al final (fecha, tipo de documento), cada uno sin cortes de línea; el separador
  # queda pegado a la parte anterior, así en el celular no queda "· 2026" solo en una línea.
  def vehicle_identity(vehicle, plate: nil, extra: nil)
    name = vehicle_name(vehicle)
    parts = [tag.strong(plate.presence || vehicle.plate, class: "text-body"), name, *Array(extra)].compact_blank
    pieces = parts.each_with_index.map do |part, index|
      text = index < parts.size - 1 ? safe_join([part, "\u00A0·"]) : part
      part.equal?(name) ? text : tag.span(text, class: "text-nowrap")
    end
    safe_join([tag.i(class: "bi bi-truck-front me-1", "aria-hidden": true), safe_join(pieces, " ")])
  end

  # Igual que el envoltorio de Rails (field_with_errors) para un campo cuyo error queda en la
  # asociación (:user) y no en la columna del formulario (:user_id), que Rails no marca solo.
  def vehicle_field_with_errors(invalid, &block)
    content = capture(&block)
    invalid ? tag.div(content, class: "field_with_errors") : content
  end

  # Texto de la opción de un chofer: avisa si ya maneja otro vehículo.
  def vehicle_driver_option_label(driver)
    plate = driver.active_assignment&.vehicle&.plate
    plate ? "#{driver.email} (ya asignado a #{plate})" : driver.email
  end

  # "11 de junio de 2026 · hace 4 meses".
  def vehicle_assignment_since(date)
    return "" if date.blank?

    days = (Date.current - date).to_i
    text = "Desde el #{l(date, format: :long)}"
    return text unless days.positive?

    safe_join([text, " · ", tag.span("hace #{vehicle_days_in_words(days)}", class: "text-nowrap")])
  end

  # "4 días", "3 meses", "más de 1 año".
  def vehicle_days_in_words(days)
    if days < 60
      pluralize(days, "día", plural: "días")
    elsif days < 365
      pluralize((days / 30.0).round, "mes", plural: "meses")
    else
      years = days / 365
      "más de #{pluralize(years, 'año', plural: 'años')}"
    end
  end
end
