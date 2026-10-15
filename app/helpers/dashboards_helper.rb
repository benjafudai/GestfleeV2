module DashboardsHelper
  # Fondo y color del ícono en círculo. primary/success/warning usan las clases
  # de gf-action-icon; el resto, los tonos suaves de Bootstrap (mismos tokens).
  DASHBOARD_TONE_CLASSES = {
    primary:   "is-primary",
    success:   "is-success",
    warning:   "is-warning",
    danger:    "bg-danger-subtle text-danger",
    info:      "bg-info-subtle text-info-emphasis",
    secondary: "bg-secondary-subtle text-secondary-emphasis"
  }.freeze

  CHECKLIST_SUBMISSION_STATUS_LABELS = {
    "pending"  => "Pendiente",
    "approved" => "Aprobado",
    "rejected" => "Rechazado"
  }.freeze

  def dashboard_icon_circle(icon, tone = :primary, extra_class = nil)
    classes = ["gf-action-icon", DASHBOARD_TONE_CLASSES.fetch(tone.to_sym, "is-primary"), extra_class].compact.join(" ")
    tag.span(tag.i(class: "bi #{icon}"), class: classes, "aria-hidden": true)
  end

  # Indicador del dashboard: ícono en círculo + etiqueta + valor (mismo patrón que
  # los indicadores de Costos y Análisis de fallas). En el celular el círculo va
  # sobre la etiqueta; el valor queda abajo para que se alinee con el de la tarjeta
  # vecina aunque una etiqueta ocupe dos líneas.
  def dashboard_stat(label, value, icon:, tone: :primary)
    tag.div(class: "card h-100") do
      tag.div(class: "card-body d-flex flex-column flex-sm-row gap-2 gap-sm-3") do
        body = tag.div(class: "min-w-0 flex-grow-1 d-flex flex-column") do
          tag.div(label, class: "small text-muted") + tag.div(value, class: "h4 mb-0 mt-auto text-nowrap")
        end
        dashboard_icon_circle(icon, tone, "align-self-start align-self-sm-center") + body
      end
    end
  end

  # Tarjeta de acceso a un módulo: redondeada, ícono en círculo y toda la tarjeta clickeable.
  # El contador opcional ("1 plantilla") va bajo el título, así el encabezado no se
  # parte en dos líneas y el texto queda a la misma altura que en las tarjetas vecinas.
  def dashboard_action_card(title, text, path:, link_text:, icon:, tone: :primary, count: nil)
    tag.div(class: "gf-action-card") do
      heading = tag.h2(title, class: "gf-action-title")
      if count.present?
        heading = tag.div(class: "min-w-0", style: "flex: 1 1 8rem;") do
          heading + tag.div(count, class: "small text-muted text-truncate")
        end
      end
      head = tag.div(class: "gf-action-head") { dashboard_icon_circle(icon, tone) + heading }
      link = link_to(path, class: "gf-action-link") do
        safe_join([link_text, " ", tag.i(class: "bi bi-arrow-right", "aria-hidden": true)])
      end
      safe_join([head, tag.p(text, class: "gf-action-text"), link])
    end
  end

  # "Hola, correo · martes 14 de octubre" bajo el título del panel
  # (en celular la fecha baja a su propia línea).
  def dashboard_greeting(user)
    safe_join([
      "Hola, ", tag.span(user.email, class: "text-body fw-bold"),
      tag.span(" · ", class: "d-none d-sm-inline"),
      tag.span(l(Date.current, format: "%A %-d de %B"), class: "d-block d-sm-inline")
    ])
  end

  def dashboard_checklist_status_label(status)
    CHECKLIST_SUBMISSION_STATUS_LABELS[status.to_s] || status.to_s.humanize
  end

  # Estado del documento calculado con la fecha de hoy (mismas reglas que
  # ComplianceChecker), para que nunca muestre un estado desactualizado.
  def dashboard_document_status(document)
    return document.status.to_s if document.due_on.blank?

    if document.due_on < Date.current
      "expired"
    elsif document.due_on <= 30.days.from_now.to_date
      "expiring"
    else
      "ok"
    end
  end

  # "Vence el 21/10/2026 · en 7 días" / "Venció el 02/10/2026"
  def dashboard_due_text(date)
    return "Sin fecha de vencimiento" if date.blank?

    days = (date - Date.current).to_i
    if days.negative?
      "Venció el #{l(date)}"
    elsif days.zero?
      "Vence hoy"
    elsif days == 1
      "Vence mañana"
    elsif days <= 30
      "Vence el #{l(date)} · en #{days} días"
    else
      "Vence el #{l(date)}"
    end
  end

  # Píldora de stock bajo: "4 en stock" (amarilla) o "Sin stock" (roja).
  def dashboard_low_stock_badge(part)
    if part.stock.to_d.positive?
      qty = number_with_precision(part.stock, precision: 2, strip_insignificant_zeros: true, separator: ",", delimiter: ".")
      status_badge("#{qty} en stock", "expiring", class: "text-nowrap")
    else
      status_badge("Sin stock", "expired", class: "text-nowrap")
    end
  end

  # Mes en curso para el encabezado de la tarjeta de categorías: "octubre de 2026".
  def dashboard_month_label(date = Date.current)
    l(date, format: "%B de %Y")
  end
end
