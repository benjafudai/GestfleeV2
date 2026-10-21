module MaintenancePlansHelper
  # Título de tarjeta con su ícono en un círculo suave (órdenes de trabajo y planes).
  def maintenance_card_title(title, icon:, tone: "primary", tag_name: :h5)
    circle = tag.span(tag.i(class: "bi #{icon}"),
                      class: "d-inline-flex align-items-center justify-content-center flex-shrink-0 rounded-circle " \
                             "bg-#{tone}-subtle text-#{tone}-emphasis lh-1 p-2",
                      "aria-hidden": true)
    content_tag(tag_name, safe_join([circle, title]), class: "mb-0 d-flex align-items-center gap-2")
  end

  # Frecuencias definidas del plan como pares [ícono, texto]: "10.000 km", "500 h", "180 días".
  def maintenance_plan_intervals(plan)
    intervals = []
    intervals << ["bi-speedometer2", "#{number_with_delimiter(plan.interval_km)} km"] if plan.interval_km.present?
    intervals << ["bi-hourglass-split", "#{number_with_delimiter(plan.interval_hours)} h"] if plan.interval_hours.present?
    if plan.interval_days.present?
      intervals << ["bi-calendar3", "#{number_with_delimiter(plan.interval_days)} #{plan.interval_days == 1 ? 'día' : 'días'}"]
    end
    intervals
  end

  # Píldoras neutras con cada frecuencia, o un texto si el plan no tiene ninguna.
  def maintenance_plan_interval_badges(plan, empty: "Sin frecuencia")
    intervals = maintenance_plan_intervals(plan)
    return tag.span(empty, class: "text-muted") if intervals.empty?

    badges = intervals.map do |icon, text|
      tag.span(safe_join([tag.i(class: "bi #{icon} me-1", "aria-hidden": true), text]), class: "badge text-bg-light")
    end
    tag.span(safe_join(badges), class: "d-inline-flex gap-1")
  end

  # Minutos a texto: 45 → "45 min"; 135 → "2 h 15 min"; 120 → "2 h".
  def maintenance_plan_duration(minutes)
    return if minutes.blank?

    hours, mins = minutes.to_i.divmod(60)
    [("#{hours} h" if hours.positive?), ("#{mins} min" if mins.positive? || hours.zero?)].compact.join(" ")
  end

  def maintenance_plan_task_count(count)
    count == 1 ? "1 tarea" : "#{number_with_delimiter(count)} tareas"
  end
end
