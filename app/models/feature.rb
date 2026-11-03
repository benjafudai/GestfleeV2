# Secciones de la app que el superadmin puede activar o desactivar por empresa
# y, dentro de la empresa, por usuario (FeatureOverride). Todas vienen activas;
# solo cambia lo que el superadmin cambie. Vehículos, Dashboard y Usuarios no
# están aquí porque el resto de la app depende de ellos.
#
# Orden de prioridad: excepción del usuario, excepción de la empresa, activa.
# El superadmin siempre ve todo.
module Feature
  SECTIONS = {
    "Flota" => {
      "checklists"  => { name: "Checklists", description: "Plantillas, checklist del día y revisión de envíos." },
      "combustible" => { name: "Combustible", description: "Cargas de combustible y alertas de consumo." }
    },
    "Mantención" => {
      "ordenes_trabajo"   => { name: "Órdenes de trabajo", description: "Trabajos de taller, tareas y repuestos usados." },
      "planes_mantencion" => { name: "Planes de mantención", description: "Planes por kilometraje u horómetro." },
      "incidentes"        => { name: "Incidentes", description: "Reporte y seguimiento de fallas e incidentes." }
    },
    "Inventario" => {
      "repuestos"       => { name: "Repuestos", description: "Catálogo de repuestos, stock y cotizaciones." },
      "buscar_repuesto" => { name: "Buscar repuesto", description: "Búsqueda en bodega y en tiendas externas." },
      "suministros"     => { name: "Suministros", description: "Solicitudes de suministros a bodega." },
      "productos"       => { name: "Productos", description: "Inventario de productos con entradas y salidas." },
      "entregas"        => { name: "Entregas", description: "Entregas de productos con comprobante." }
    },
    "Análisis" => {
      "costos"          => { name: "Costos", description: "Gastos por vehículo y categoría." },
      "analisis_fallas" => { name: "Análisis de fallas", description: "Fallas más frecuentes y su costo." },
      "alertas"         => { name: "Alertas", description: "Documentos por vencer y avisos de la flota." },
      "resumen_semanal" => { name: "Resumen semanal", description: "PDF semanal por correo a los administradores." }
    }
  }.freeze

  CATALOG = SECTIONS.values.reduce({}, :merge).freeze

  def self.keys
    CATALOG.keys
  end

  def self.name_for(key)
    CATALOG.dig(key.to_s, :name) || key.to_s
  end

  def self.enabled?(user, key)
    key = key.to_s
    return false unless user && CATALOG.key?(key)
    return true if user.superadmin?

    user_override = FeatureOverride.current_for(user, key)
    return user_override.enabled if user_override

    company_enabled?(user.company, key)
  end

  def self.company_enabled?(company, key)
    return false unless company

    override = FeatureOverride.current_for(company, key)
    override ? override.enabled : true
  end
end
