module ApplicationHelper
  DOCUMENT_STATUS_LABELS = {
    "ok"       => "Vigente",
    "expiring" => "Por Vencer",
    "expired"  => "Vencido"
  }.freeze

  VEHICLE_STATUS_LABELS = {
    "active"      => "Activo",
    "maintenance" => "Mantenimiento",
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
    "in_review" => "En Revisión",
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
    "in_progress" => "En Progreso",
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
    "permiso_circulacion" => "Permiso de Circulación",
    "revision_tecnica"    => "Revisión Técnica",
    "seguro"              => "Seguro",
    "padron"              => "Padrón",
    "otro"                => "Otro"
  }.freeze

  USER_DOC_TYPE_LABELS = {
    "licencia_conducir"     => "Licencia de Conducir",
    "carnet_identidad"      => "Carnet de Identidad",
    "examen_preocupacional" => "Examen Preocupacional",
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
