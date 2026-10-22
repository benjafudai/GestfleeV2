module NavigationHelper
  # Sidebar menu per role. Each section has an optional title and items:
  #   label, path, icon (Font Awesome name), match (path prefix or :dashboard),
  #   tone (:danger to highlight the item).
  def sidebar_sections
    @sidebar_sections ||= build_sidebar_sections
  end

  def nav_item_active?(item)
    if item[:match] == :dashboard
      request.path.in?(["/", "/dashboard"])
    elsif request.path.match?(%r{\A/vehicles/\d+/fuel_fills})
      item[:match] == "/fuel_fills"
    else
      request.path.start_with?(item[:match])
    end
  end

  # Pages reachable from the topbar instead of the sidebar, or through links
  # from other pages (e.g. the analista opening a vehicle), still get a title.
  def current_nav_item
    items = sidebar_sections.flat_map { |section| section[:items] }
    items += [nav_item("Notificaciones", notifications_path, "fa-bell", "/notifications")]
    items.find { |item| nav_item_active?(item) } || fallback_nav_item
  end

  # El chofer ve «Mis entregas» solo si su empresa registra productos.
  def company_sells_products?
    return @company_sells_products if defined?(@company_sells_products)

    @company_sells_products = current_user.company_id.present? && Product.unscoped.exists?(company_id: current_user.company_id)
  end

  def user_initials(user)
    user.email.to_s.first.upcase
  end

  private

  def fallback_nav_item
    path = request.path
    if path.match?(%r{\A/vehicles/\d+/fuel_fills})
      nav_item("Combustible", fuel_fills_path, "fa-gas-pump", path)
    elsif path.start_with?("/vehicles")
      nav_item("Vehículos", vehicles_path, "fa-truck-front", path)
    elsif path.start_with?("/users")
      nav_item("Usuarios", users_path, "fa-users", path)
    elsif path.start_with?("/checklist")
      nav_item("Checklists", checklist_submissions_path, "fa-list-check", path)
    elsif path.start_with?("/incidents")
      nav_item("Incidentes", incidents_path, "fa-triangle-exclamation", path)
    elsif path.start_with?("/alerts")
      nav_item("Alertas", alerts_path, "fa-circle-exclamation", path)
    end
  end

  def nav_item(label, path, icon, match, tone: nil)
    { label: label, path: path, icon: icon, match: match, tone: tone }
  end

  def build_sidebar_sections
    dashboard = nav_item("Dashboard", dashboard_path, "fa-gauge-high", :dashboard)

    case current_user.role
    when "superadmin"
      # Superadmin has read access to every section (see the policies), so the
      # menu lists them all, not just company/user administration.
      [
        { title: nil, items: [dashboard] },
        { title: "Administración", items: [
          nav_item("Empresas", companies_path, "fa-building", "/companies"),
          nav_item("Usuarios", users_path, "fa-users", "/users"),
          nav_item("Solicitudes de clave", password_reset_requests_path, "fa-key", "/password_reset_requests")
        ] },
        { title: "Flota", items: [
          nav_item("Vehículos", vehicles_path, "fa-truck-front", "/vehicles"),
          nav_item("Checklists", checklist_templates_path, "fa-list-check", "/checklist"),
          nav_item("Combustible", fuel_fills_path, "fa-gas-pump", "/fuel_fills")
        ] },
        { title: "Mantención", items: [
          nav_item("Órdenes de trabajo", work_orders_path, "fa-screwdriver-wrench", "/work_orders"),
          nav_item("Planes de mantención", maintenance_plans_path, "fa-clipboard-check", "/maintenance_plans"),
          nav_item("Incidentes", incidents_path, "fa-triangle-exclamation", "/incidents")
        ] },
        { title: "Inventario", items: [
          nav_item("Repuestos", parts_path, "fa-boxes-stacked", "/parts"),
          nav_item("Buscar repuesto", part_search_path, "fa-magnifying-glass", "/buscar_repuestos"),
          nav_item("Suministros", supply_requests_path, "fa-cart-plus", "/supply_requests"),
          nav_item("Productos", products_path, "fa-cubes", "/productos"),
          nav_item("Entregas", deliveries_path, "fa-truck-ramp-box", "/entregas")
        ] },
        { title: "Análisis", items: [
          nav_item("Costos", expenses_path, "fa-coins", "/expenses"),
          nav_item("Análisis de fallas", failure_analytics_path, "fa-chart-line", "/failure_analytics")
        ] }
      ]
    when "admin"
      [
        { title: nil, items: [dashboard] },
        { title: "Flota", items: [
          nav_item("Vehículos", vehicles_path, "fa-truck-front", "/vehicles"),
          nav_item("Checklists", checklist_templates_path, "fa-list-check", "/checklist"),
          nav_item("Combustible", fuel_fills_path, "fa-gas-pump", "/fuel_fills")
        ] },
        { title: "Mantención", items: [
          nav_item("Órdenes de trabajo", work_orders_path, "fa-screwdriver-wrench", "/work_orders"),
          nav_item("Planes de mantención", maintenance_plans_path, "fa-clipboard-check", "/maintenance_plans"),
          nav_item("Incidentes", incidents_path, "fa-triangle-exclamation", "/incidents")
        ] },
        { title: "Inventario", items: [
          nav_item("Repuestos", parts_path, "fa-boxes-stacked", "/parts"),
          nav_item("Buscar repuesto", part_search_path, "fa-magnifying-glass", "/buscar_repuestos"),
          nav_item("Suministros", supply_requests_path, "fa-cart-plus", "/supply_requests"),
          nav_item("Productos", products_path, "fa-cubes", "/productos"),
          nav_item("Entregas", deliveries_path, "fa-truck-ramp-box", "/entregas")
        ] },
        { title: "Análisis", items: [
          nav_item("Costos", expenses_path, "fa-coins", "/expenses"),
          nav_item("Análisis de fallas", failure_analytics_path, "fa-chart-line", "/failure_analytics"),
          nav_item("Alertas", alerts_path, "fa-circle-exclamation", "/alerts", tone: :danger),
          nav_item("Resumen semanal", weekly_summary_path, "fa-file-pdf", "/resumen_semanal")
        ] },
        { title: "Administración", items: [
          nav_item("Usuarios", users_path, "fa-users", "/users")
        ] }
      ]
    when "chofer"
      [
        { title: nil, items: [
          nav_item("Mi unidad", dashboard_path, "fa-gauge-high", :dashboard),
          nav_item("Checklist del día", checklist_submissions_path, "fa-clipboard-check", "/checklist_submissions"),
          nav_item("Incidentes", incidents_path, "fa-triangle-exclamation", "/incidents"),
          nav_item("Combustible", fuel_fills_path, "fa-gas-pump", "/fuel_fills"),
          (nav_item("Mis entregas", deliveries_path, "fa-truck-ramp-box", "/entregas") if company_sells_products?)
        ].compact }
      ]
    when "mecanico"
      [
        { title: nil, items: [dashboard] },
        { title: "Taller", items: [
          nav_item("Órdenes de trabajo", work_orders_path, "fa-screwdriver-wrench", "/work_orders"),
          nav_item("Planes de mantención", maintenance_plans_path, "fa-clipboard-check", "/maintenance_plans"),
          nav_item("Incidentes", incidents_path, "fa-triangle-exclamation", "/incidents")
        ] },
        { title: "Inventario", items: [
          nav_item("Repuestos", parts_path, "fa-boxes-stacked", "/parts"),
          nav_item("Buscar repuesto", part_search_path, "fa-magnifying-glass", "/buscar_repuestos"),
          nav_item("Suministros", supply_requests_path, "fa-cart-plus", "/supply_requests")
        ] }
      ]
    when "analista"
      [
        { title: nil, items: [dashboard] },
        { title: "Análisis", items: [
          nav_item("Costos", expenses_path, "fa-coins", "/expenses"),
          nav_item("Análisis de fallas", failure_analytics_path, "fa-chart-line", "/failure_analytics"),
          nav_item("Alertas", alerts_path, "fa-circle-exclamation", "/alerts", tone: :danger)
        ] },
        { title: "Operación", items: [
          nav_item("Combustible", fuel_fills_path, "fa-gas-pump", "/fuel_fills"),
          nav_item("Repuestos", parts_path, "fa-boxes-stacked", "/parts"),
          nav_item("Buscar repuesto", part_search_path, "fa-magnifying-glass", "/buscar_repuestos"),
          nav_item("Suministros", supply_requests_path, "fa-cart-plus", "/supply_requests"),
          nav_item("Productos", products_path, "fa-cubes", "/productos"),
          nav_item("Entregas", deliveries_path, "fa-truck-ramp-box", "/entregas")
        ] }
      ]
    when "bodeguero"
      [
        { title: nil, items: [dashboard] },
        { title: "Inventario", items: [
          nav_item("Repuestos", parts_path, "fa-boxes-stacked", "/parts"),
          nav_item("Buscar repuesto", part_search_path, "fa-magnifying-glass", "/buscar_repuestos"),
          nav_item("Suministros", supply_requests_path, "fa-cart-plus", "/supply_requests"),
          nav_item("Productos", products_path, "fa-cubes", "/productos"),
          nav_item("Entregas", deliveries_path, "fa-truck-ramp-box", "/entregas")
        ] }
      ]
    else
      []
    end
  end
end
