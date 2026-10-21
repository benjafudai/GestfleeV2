module IncidentsHelper
  # ---------- Incidentes ----------

  # Color de la gravedad: de azul (baja) a rojo (alta / crítica).
  INCIDENT_SEVERITY_TONES = {
    "low"      => "info",
    "medium"   => "warning",
    "high"     => "danger",
    "critical" => "danger"
  }.freeze

  INCIDENT_STATUS_ICONS = {
    "pending"   => "bi-hourglass-split",
    "in_review" => "bi-search",
    "resolved"  => "bi-check-circle"
  }.freeze

  # Etiquetas de los contadores del listado, en singular y plural ("1 Pendiente", "2 Pendientes").
  INCIDENT_STATUS_COUNT_LABELS = {
    "pending"   => ["Pendiente", "Pendientes"],
    "in_review" => ["En revisión", "En revisión"],
    "resolved"  => ["Resuelto", "Resueltos"]
  }.freeze

  # Qué significa cada estado, para el panel de estado del detalle.
  INCIDENT_STATUS_HINTS = {
    "pending"   => "El incidente fue reportado y espera revisión.",
    "in_review" => "El incidente se está revisando.",
    "resolved"  => "El incidente fue atendido y quedó resuelto."
  }.freeze

  INCIDENT_SEVERITY_ICONS = {
    "low"      => "bi-info-circle",
    "medium"   => "bi-exclamation-circle",
    "high"     => "bi-exclamation-triangle",
    "critical" => "bi-exclamation-octagon"
  }.freeze

  # Qué significa cada gravedad, para el panel del detalle.
  INCIDENT_SEVERITY_HINTS = {
    "low"      => "Afecta poco la operación del vehículo.",
    "medium"   => "Afecta en parte la operación del vehículo.",
    "high"     => "Afecta seriamente la operación del vehículo.",
    "critical" => "Impide o pone en riesgo la operación del vehículo."
  }.freeze

  # Etiqueta de gravedad en píldora; la crítica lleva además un ícono.
  def incident_severity_badge(severity)
    tone = INCIDENT_SEVERITY_TONES.fetch(severity.to_s, "secondary")
    icon = tag.i(class: "bi bi-exclamation-octagon-fill me-1", "aria-hidden": true) if severity.to_s == "critical"
    tag.span(safe_join([icon, incident_severity_label(severity)].compact), class: "badge text-bg-#{tone}")
  end

  def incident_status_icon(status)
    INCIDENT_STATUS_ICONS.fetch(status.to_s, "bi-circle")
  end

  # Etiqueta del contador según la cantidad: "Pendiente" con 1, "Pendientes" con 0 o más de 1.
  def incident_status_count_label(status, count)
    singular, plural = INCIDENT_STATUS_COUNT_LABELS[status.to_s]
    return incident_status_label(status) unless singular

    count == 1 ? singular : plural
  end

  def incident_status_hint(status)
    INCIDENT_STATUS_HINTS[status.to_s]
  end

  # Círculo de color con un ícono (mismo lenguaje que las tarjetas del dashboard).
  def incident_icon_circle(icon, tone = "primary", **options)
    classes = ["gf-action-icon", "bg-#{tone}-subtle", "text-#{tone}-emphasis", options.delete(:class)].compact.join(" ")
    tag.span(tag.i(class: "bi #{icon}"), class: classes, "aria-hidden": true, **options)
  end

  # Círculo del estado, con el mismo tono que su etiqueta.
  def incident_status_icon_circle(status)
    incident_icon_circle(incident_status_icon(status), status_tone(status))
  end

  # Círculo de la gravedad, con el mismo tono que su etiqueta.
  def incident_severity_icon_circle(severity)
    incident_icon_circle(INCIDENT_SEVERITY_ICONS.fetch(severity.to_s, "bi-exclamation-circle"),
                         INCIDENT_SEVERITY_TONES.fetch(severity.to_s, "secondary"))
  end

  def incident_severity_hint(severity)
    INCIDENT_SEVERITY_HINTS[severity.to_s]
  end

  # Título de tarjeta con ícono en círculo pequeño.
  def incident_card_title(title, icon:, tone: "primary", tag_name: :h5, heading_class: nil)
    content_tag(tag_name, safe_join([incident_card_title_circle(icon, tone), title]),
                class: ["mb-0 d-flex align-items-center gap-2", heading_class].compact.join(" "))
  end

  def incident_card_title_circle(icon, tone = "primary")
    tag.span(tag.i(class: "bi #{icon}"),
             class: "d-inline-flex align-items-center justify-content-center flex-shrink-0 rounded-circle " \
                    "bg-#{tone}-subtle text-#{tone}-emphasis lh-1 p-2",
             "aria-hidden": true)
  end

  # Gravedad en texto corto y con su color ("Gravedad alta"), para la columna Estado en celular.
  def incident_severity_text(severity, **options)
    tone = INCIDENT_SEVERITY_TONES.fetch(severity.to_s, "secondary")
    classes = ["small fw-semibold text-#{tone}-emphasis", options.delete(:class)].compact.join(" ")
    tag.span("Gravedad #{incident_severity_label(severity).to_s.downcase}", class: classes, **options)
  end

  # "Toyota Hilux 2.4" (marca y modelo, lo que exista).
  def incident_vehicle_model(vehicle)
    return "" unless vehicle

    [vehicle.brand, vehicle.model].compact_blank.join(" ")
  end

  # "SBLW-17 · Toyota Hilux 2.4"
  def incident_vehicle_label(vehicle)
    return "Sin vehículo" unless vehicle

    [vehicle.plate, incident_vehicle_model(vehicle)].compact_blank.join(" · ")
  end

  # Patente con enlace solo si el usuario puede ver la ficha del vehículo
  # (chofer y mecánico no tienen acceso a Vehículos).
  def incident_vehicle_link(vehicle, **options)
    return tag.span("Sin vehículo", class: "text-muted") unless vehicle

    if policy(vehicle).show?
      link_to vehicle.plate, vehicle_path(vehicle), **options
    else
      tag.span(vehicle.plate, **options)
    end
  end

  # Coordenadas legibles y copiables: "-33.4500, -70.6600".
  def incident_coordinates(incident)
    Kernel.format("%.4f, %.4f", incident.latitude.to_f, incident.longitude.to_f)
  end

  def incident_map_url(incident)
    "https://www.google.com/maps?q=#{incident.latitude},#{incident.longitude}"
  end

  def incident_map_embed_url(incident)
    "https://maps.google.com/maps?q=#{incident.latitude},#{incident.longitude}&z=15&output=embed"
  end

  # ---------- Checklists (plantillas y envíos) ----------

  # Título de tarjeta de los checklists: mismo círculo que incident_card_title, como <h2> de tamaño h5.
  # Con subtitle, el texto chico queda bajo el título y alineado con él (no bajo el círculo).
  def checklist_card_title(title, icon:, tone: "primary", subtitle: nil)
    return incident_card_title(title, icon: icon, tone: tone, tag_name: :h2, heading_class: "h5") if subtitle.blank?

    tag.div(class: "d-flex align-items-center gap-2 min-w-0") do
      safe_join([
        incident_card_title_circle(icon, tone),
        tag.div(class: "min-w-0") do
          safe_join([tag.h2(title, class: "h5 mb-0"), tag.div(subtitle, class: "small text-muted fw-normal")])
        end
      ])
    end
  end

  CHECKLIST_STATUS_COUNT_LABELS = {
    "pending"  => ["Pendiente", "Pendientes"],
    "approved" => ["Aprobado", "Aprobados"],
    "rejected" => ["Rechazado", "Rechazados"]
  }.freeze

  # "1 Pendiente" / "3 Pendientes" en los contadores del listado de checklists.
  def checklist_status_count_label(status, count)
    singular, plural = CHECKLIST_STATUS_COUNT_LABELS.fetch(status.to_s) { [status.to_s.humanize] * 2 }
    count == 1 ? singular : plural
  end

  # ---------- Alertas de cumplimiento ----------

  DOCUMENT_STATUS_ICONS = {
    "ok"       => "bi-check-circle",
    "expiring" => "bi-hourglass-split",
    "expired"  => "bi-exclamation-octagon"
  }.freeze

  def alert_document_icon_circle(status, **options)
    incident_icon_circle(DOCUMENT_STATUS_ICONS.fetch(status.to_s, "bi-file-earmark-text"), status_tone(status), **options)
  end

  # "Venció el 01/10/2026 · hace 13 días" / "Vence hoy" / "Vence mañana · 15/10/2026" / "Vence el 27/10/2026 · en 13 días"
  def alert_due_text(due_on)
    return "Sin fecha de vencimiento" if due_on.blank?

    date = due_on.to_date
    days = (date - Date.current).to_i
    case days
    when 0 then "Vence hoy"
    when 1 then "Vence mañana · #{l(date)}"
    when -1 then "Venció ayer · #{l(date)}"
    else
      days.negative? ? "Venció el #{l(date)} · hace #{alert_days(-days)}" : "Vence el #{l(date)} · en #{alert_days(days)}"
    end
  end

  def alert_days(count)
    count == 1 ? "1 día" : "#{number_with_delimiter(count)} días"
  end

  # ---------- Notificaciones ----------

  NOTIFICATION_ICONS = {
    "VehicleDocument"         => "bi-file-earmark-text",
    "UserDocument"            => "bi-person-vcard",
    "FuelFill"                => "bi-fuel-pump",
    "PasswordResetRequest"    => "bi-key",
    "RoadsideAssistanceEvent" => "bi-life-preserver",
    "Incident"                => "bi-exclamation-triangle",
    "WorkOrder"               => "bi-tools",
    "SupplyRequest"           => "bi-box-seam"
  }.freeze

  NOTIFICATION_TONES = {
    "FuelFill"                => "warning",
    "RoadsideAssistanceEvent" => "danger",
    "Incident"                => "warning"
  }.freeze

  # Títulos que el sistema guardaba con mayúsculas en cada palabra.
  NOTIFICATION_TITLE_FIXES = {
    "Documento Vencido"                       => "Documento vencido",
    "Alerta de Consumo"                       => "Alerta de consumo",
    "¡Emergencia Reportada!"                  => "¡Emergencia reportada!",
    "Solicitud de Recuperación de Contraseña" => "Solicitud de recuperación de contraseña"
  }.freeze

  def notification_icon_circle(notification)
    icon = NOTIFICATION_ICONS.fetch(notification.notifiable_type.to_s, "bi-bell")
    # Las ya leídas quedan en gris para que destaquen las nuevas.
    tone = notification.read? ? "secondary" : notification_tone(notification)
    incident_icon_circle(icon, tone)
  end

  def notification_tone(notification)
    title = notification.title.to_s
    return "danger" if title.match?(/vencid/i)
    return "warning" if title.match?(/por vencer/i)

    NOTIFICATION_TONES.fetch(notification.notifiable_type.to_s, "primary")
  end

  def notification_title_text(notification)
    title = notification.title.to_s
    NOTIFICATION_TITLE_FIXES.each do |old, new|
      return title.sub(old, new) if title.start_with?(old)
    end
    title
  end

  # Título con el sujeto corto (patente) sin cortarse en el guion: "Documento vencido: TKVD-28".
  def notification_title(notification)
    prefix, subject = notification_title_text(notification).split(": ", 2)
    return prefix if subject.blank?
    return "#{prefix}: #{subject}" if subject.length > 24

    safe_join([prefix, ": ", tag.span(subject, class: "text-nowrap")])
  end

  # Los avisos antiguos guardaban el tipo de documento en bruto ("revision_tecnica"),
  # fechas ISO ("2026-10-21"), decimales con punto y repetían la patente al final.
  # Se muestran con el mismo formato que los avisos nuevos.
  def notification_message_text(notification)
    message = notification.message.to_s

    if (match = message.match(/\AEl documento (\w+) (ha vencido el |vencerá pronto \()(\d{4}-\d{2}-\d{2})\)?\.(?: - .*)?\z/))
      label = notification_doc_type_label(match[1])
      date = Date.iso8601(match[3]) rescue nil
      if date
        verb = match[2].start_with?("ha vencido") ? "venció" : "vence"
        return "#{label} #{verb} el #{l(date, format: :long)}."
      end
    end

    message.gsub(/(\d+)\.(\d+)(?= km\/l)/, '\1,\2')
  end

  def notification_doc_type_label(doc_type)
    if ApplicationHelper::VEHICLE_DOC_TYPE_LABELS.key?(doc_type)
      vehicle_doc_type_label(doc_type)
    elsif ApplicationHelper::USER_DOC_TYPE_LABELS.key?(doc_type)
      user_doc_type_label(doc_type)
    else
      doc_type.to_s.humanize
    end
  end
end
