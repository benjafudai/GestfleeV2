module CompaniesHelper
  # Módulos opcionales de una empresa: atributo de configuración, rol que habilita y textos.
  COMPANY_MODULES = [
    { attribute: :has_mechanic,  role: "mecanico",  label: "Mecánico",
      hint: "Permite crear usuarios con rol mecánico y gestionar órdenes de trabajo y mantenciones." },
    { attribute: :has_analyst,   role: "analista",  label: "Analista",
      hint: "Permite crear usuarios con rol analista para revisar costos, consumo y reportes." },
    { attribute: :has_bodeguero, role: "bodeguero", label: "Bodeguero",
      hint: "Permite crear usuarios con rol bodeguero para gestionar inventario y solicitudes de suministros." }
  ].freeze

  # Usuarios y vehículos de cada empresa del listado en dos consultas agrupadas,
  # en vez de dos COUNT por tarjeta: { users: { id => n }, vehicles: { id => n } }.
  def company_counts(companies)
    ids = companies.map(&:id)
    return { users: {}, vehicles: {} } if ids.empty?

    { users: User.where(company_id: ids).group(:company_id).count,
      vehicles: Vehicle.where(company_id: ids).group(:company_id).count }
  end

  def company_module_enabled?(company, mod)
    company.public_send("#{mod[:attribute]}?")
  end

  # Píldora de un módulo: verde con check si está activo, gris si no.
  def company_module_pill(company, mod)
    enabled = company_module_enabled?(company, mod)
    icon = enabled ? "bi-check2-circle" : "bi-dash-circle"
    tag.span(safe_join([tag.i(class: "bi #{icon}", "aria-hidden": true), mod[:label]]),
             class: ["pill gap-1", ("success" if enabled), ("opacity-75" unless enabled)].compact.join(" "),
             title: enabled ? "Módulo activo" : "Módulo desactivado")
  end
end
