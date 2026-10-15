module VehicleDocumentsHelper
  VEHICLE_DOC_ICONS = {
    "permiso_circulacion" => "bi-card-checklist",
    "revision_tecnica"    => "bi-clipboard-check",
    "seguro"              => "bi-shield-check",
    "padron"              => "bi-file-earmark-text",
    "otro"                => "bi-file-earmark"
  }.freeze

  # Estado según la fecha de vencimiento, con las mismas reglas que ComplianceChecker
  # (vencido si ya pasó, por vencer dentro de 30 días). Así la ficha no depende de que haya
  # corrido el chequeo programado ni de lo que se eligió a mano en el formulario.
  # Sin fecha, se usa el estado guardado.
  def vehicle_document_effective_status(document)
    return document.status.to_s.presence if document.due_on.blank?

    if document.due_on < Date.current
      "expired"
    elsif document.due_on <= 30.days.from_now.to_date
      "expiring"
    else
      "ok"
    end
  end

  # Ícono del tipo de documento en un círculo del mismo tono que su estado.
  def vehicle_document_icon_circle(document, extra_class: nil)
    tone = status_tone(vehicle_document_effective_status(document))
    icon = VEHICLE_DOC_ICONS.fetch(document.doc_type.to_s, "bi-file-earmark")
    tag.span(tag.i(class: "bi #{icon}"),
             class: ["gf-action-icon bg-#{tone}-subtle text-#{tone}-emphasis", extra_class].compact.join(" "),
             "aria-hidden": true)
  end

  def vehicle_document_status_badge(document)
    status = vehicle_document_effective_status(document)
    return if status.blank?

    status_badge(document_status_label(status), status)
  end

  # "Vence el 23 de diciembre de 2026 · en 2 meses", "Vence hoy, 14 de octubre de 2026",
  # "Venció el 1 de octubre de 2026 · hace 13 días".
  def vehicle_document_due_text(document)
    return "Sin fecha de vencimiento" if document.due_on.blank?

    date = l(document.due_on, format: :long)
    days = (document.due_on - Date.current).to_i

    if days.zero?
      "Vence hoy, #{date}"
    elsif days.positive?
      safe_join(["Vence el #{date}", tag.span(" · ", class: "d-none d-sm-inline"), tag.span("en #{vehicle_days_in_words(days)}", class: "d-block d-sm-inline text-nowrap")])
    else
      safe_join(["Venció el #{date}", tag.span(" · ", class: "d-none d-sm-inline"), tag.span("hace #{vehicle_days_in_words(-days)}", class: "d-block d-sm-inline text-nowrap")])
    end
  end

  def vehicle_document_type_options
    VehicleDocument.doc_types.keys.map { |type| [vehicle_doc_type_label(type), type] }
  end

  def vehicle_document_status_options
    VehicleDocument.statuses.keys.map { |status| [document_status_label(status), status] }
  end
end
