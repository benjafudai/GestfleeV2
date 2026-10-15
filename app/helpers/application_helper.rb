module ApplicationHelper
  # Color de la etiqueta según el estado, igual en todas las pantallas.
  STATUS_TONES = {
    "ok" => "success", "active" => "success", "approved" => "success", "resolved" => "success",
    "completed" => "success", "delivered" => "success",
    "pending" => "warning", "expiring" => "warning", "maintenance" => "warning",
    "in_review" => "primary", "in_progress" => "primary", "purchasing" => "info", "requested" => "info", "received" => "primary",
    "expired" => "danger", "rejected" => "danger", "cancelled" => "danger",
    "inactive" => "secondary"
  }.freeze

  def status_tone(status)
    STATUS_TONES.fetch(status.to_s, "secondary")
  end

  # Etiqueta de estado en píldora. label: texto ya traducido.
  def status_badge(label, status, **options)
    classes = ["badge", "text-bg-#{status_tone(status)}", options.delete(:class)].compact.join(" ")
    tag.span(label, class: classes, **options)
  end

  DOCUMENT_STATUS_LABELS = {
    "ok"       => "Vigente",
    "expiring" => "Por vencer",
    "expired"  => "Vencido"
  }.freeze

  VEHICLE_STATUS_LABELS = {
    "active"      => "Activo",
    "maintenance" => "En mantención",
    "inactive"    => "Inactivo"
  }.freeze

  def document_status_label(status)
    DOCUMENT_STATUS_LABELS[status.to_s] || status.to_s.humanize
  end

  def vehicle_status_label(status)
    VEHICLE_STATUS_LABELS[status.to_s] || status.to_s.humanize
  end

  INCIDENT_SEVERITY_LABELS = {
    "low"      => "Baja",
    "medium"   => "Media",
    "high"     => "Alta",
    "critical" => "Crítica"
  }.freeze

  INCIDENT_STATUS_LABELS = {
    "pending"   => "Pendiente",
    "in_review" => "En revisión",
    "resolved"  => "Resuelto"
  }.freeze

  def incident_severity_label(severity)
    return "No especificada" if severity.blank?

    INCIDENT_SEVERITY_LABELS[severity.to_s] || severity.to_s.humanize
  end

  def incident_status_label(status)
    return "Pendiente" if status.blank?

    INCIDENT_STATUS_LABELS[status.to_s] || status.to_s.humanize
  end

  WORK_ORDER_STATUS_LABELS = {
    "pending"     => "Pendiente",
    "in_progress" => "En progreso",
    "completed"   => "Completada",
    "cancelled"   => "Cancelada"
  }.freeze

  def work_order_status_label(status)
    WORK_ORDER_STATUS_LABELS[status.to_s] || status.to_s.humanize
  end

  EXPENSE_CATEGORY_LABELS = {
    "maintenance" => "Mantenimiento",
    "fuel"        => "Combustible",
    "parts"       => "Repuestos",
    "tolls"       => "Peajes",
    "insurance"   => "Seguros",
    "other"       => "Otros"
  }.freeze

  def expense_category_label(category)
    EXPENSE_CATEGORY_LABELS[category.to_s] || category.to_s.humanize
  end

  VEHICLE_DOC_TYPE_LABELS = {
    "permiso_circulacion" => "Permiso de circulación",
    "revision_tecnica"    => "Revisión técnica",
    "seguro"              => "Seguro",
    "padron"              => "Padrón",
    "otro"                => "Otro"
  }.freeze

  USER_DOC_TYPE_LABELS = {
    "licencia_conducir"     => "Licencia de conducir",
    "carnet_identidad"      => "Carnet de identidad",
    "examen_preocupacional" => "Examen preocupacional",
    "contrato"               => "Contrato",
    "otro"                   => "Otro"
  }.freeze

  def vehicle_doc_type_label(doc_type)
    VEHICLE_DOC_TYPE_LABELS[doc_type.to_s] || doc_type.to_s.humanize
  end

  def user_doc_type_label(doc_type)
    USER_DOC_TYPE_LABELS[doc_type.to_s] || doc_type.to_s.humanize
  end
end
