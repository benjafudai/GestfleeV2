module WorkOrdersHelper
  # Ícono (Bootstrap Icons) de cada estado de una orden de trabajo.
  WORK_ORDER_STATUS_ICONS = {
    "pending"     => "bi-hourglass-split",
    "in_progress" => "bi-play-circle",
    "completed"   => "bi-check-circle",
    "cancelled"   => "bi-x-circle"
  }.freeze

  # Plural para los contadores del listado ("2 Pendientes").
  WORK_ORDER_STATUS_PLURALS = {
    "pending"     => "Pendientes",
    "in_progress" => "En progreso",
    "completed"   => "Completadas",
    "cancelled"   => "Canceladas"
  }.freeze

  # Qué significa cada estado, para el panel de estado del detalle.
  WORK_ORDER_STATUS_HINTS = {
    "pending"     => "La orden está creada y espera que comience el trabajo.",
    "in_progress" => "El trabajo está en curso. Al completarla se descuentan del inventario los repuestos utilizados.",
    "completed"   => "El trabajo terminó y los repuestos se descontaron del inventario. La orden ya no se puede modificar.",
    "cancelled"   => "La orden fue cancelada y ya no se puede modificar."
  }.freeze

  def work_order_status_icon(status)
    WORK_ORDER_STATUS_ICONS.fetch(status.to_s, "bi-circle")
  end

  def work_order_status_plural(status)
    WORK_ORDER_STATUS_PLURALS[status.to_s] || work_order_status_label(status)
  end

  # Si la orden se completó sin repuestos, no se habla de descontar inventario.
  def work_order_status_hint(status, parts_used: true)
    return "El trabajo terminó. La orden ya no se puede modificar." if status.to_s == "completed" && !parts_used

    WORK_ORDER_STATUS_HINTS[status.to_s]
  end

  # "0 de 1 completada", "2 de 5 completadas".
  def work_order_tasks_progress(done, total)
    "#{done} de #{total} #{total == 1 ? 'completada' : 'completadas'}"
  end

  # Círculo de color con el ícono del estado (mismo tono que su etiqueta).
  def work_order_status_icon_circle(status)
    tone = status_tone(status)
    tag.span(tag.i(class: "bi #{work_order_status_icon(status)}"),
             class: "gf-action-icon bg-#{tone}-subtle text-#{tone}-emphasis", "aria-hidden": true)
  end

  # Ícono de las tarjetas de conteo: círculo grande desde sm y uno compacto en el teléfono,
  # para que el texto ("Completadas") no se corte en las tarjetas de media columna.
  def work_order_status_kpi_icon(status)
    tone = status_tone(status)
    icon = tag.i(class: "bi #{work_order_status_icon(status)}")
    safe_join([
      tag.span(icon, class: "gf-action-icon bg-#{tone}-subtle text-#{tone}-emphasis d-none d-sm-grid", "aria-hidden": true),
      tag.span(icon, class: "d-inline-flex d-sm-none flex-shrink-0 rounded-circle bg-#{tone}-subtle text-#{tone}-emphasis lh-1 p-2",
                     "aria-hidden": true)
    ])
  end

  def work_order_terminal?(work_order)
    WorkOrder::TERMINAL_STATUSES.include?(work_order.status)
  end

  # Con plan es mantención preventiva; sin plan, correctiva.
  def work_order_kind_label(work_order)
    work_order.maintenance_plan ? "Preventiva" : "Correctiva"
  end

  def work_order_kind_icon(work_order)
    work_order.maintenance_plan ? "bi-calendar-check" : "bi-wrench-adjustable"
  end

  # "LGRS-91 · Scania R 450"
  def work_order_vehicle_label(vehicle)
    return "Sin vehículo" unless vehicle

    [vehicle.plate, [vehicle.brand, vehicle.model].compact_blank.join(" ")].compact_blank.join(" · ")
  end

  # Cantidades decimales sin ceros de sobra: 1,0 → "1"; 2,50 → "2,5"; 1250 → "1.250".
  def work_order_quantity(quantity)
    return "—" if quantity.nil?

    number_with_precision(quantity, precision: 2, strip_insignificant_zeros: true)
  end

  # Valor para un <input type="number"> (usa punto decimal): 1.0 → "1"; 2.5 → "2.5".
  def work_order_quantity_input(quantity)
    return if quantity.nil?

    value = quantity.to_d
    value.frac.zero? ? value.to_i.to_s : value.to_s("F")
  end

  # Opción del selector de repuestos: "FIL-001 · Filtro de aceite (stock: 12)".
  def work_order_part_option_label(part)
    "#{part.sku} · #{part.name} (stock: #{work_order_quantity(part.stock)})"
  end
end
