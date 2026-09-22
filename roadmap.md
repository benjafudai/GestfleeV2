# Roadmap de Implementación — Sistema de Gestión de Flota

> Objetivo: centralizar operación, gestión, análisis y ejecución técnica/operativa,
> con máxima trazabilidad y eficiencia.
> Roles: Admin (Azul), Chofer (Naranjo), Mecánico (Rojo), Analista (Amarillo).
> Estado actual: **Sprints 0–8 completados.**

---

## Leyenda de etiquetas

| Etiqueta | Descripción |
|---|---|
| `[SEC]` | Seguridad |
| `[PWA]` | Progressive Web App |
| `[UX]` | Frontend / Experiencia de usuario |
| `[CORE]` | Lógica de negocio |
| `[INFRA]` | Infraestructura / Servidor |

---

## ✅ Sprint 0 — Fundaciones · COMPLETADO

### 0.1 Setup técnico
- [CORE] App Rails + PostgreSQL configurada
- [UX] Tailwind CSS + layout base responsivo (sidebar desktop / bottom nav móvil)
- [CORE] i18n es-CL + zona horaria Santiago
- [INFRA] CI básico con tests + lint

### 0.2 Autenticación + Roles + Trazabilidad

**Devise endurecido:**
- [SEC][CORE] `password_length = 10..128`, `lock_strategy = :failed_attempts`, `maximum_attempts = 5`, `timeout_in = 30.minutes`
- [SEC] `Rack::Attack` — rate limiting de login por IP y por email (5 intentos / minuto)
- [SEC] Gem `pwned` — verifica si la contraseña fue filtrada en brechas públicas
- [SEC] `devise-two-factor` — 2FA con TOTP (Google Authenticator)
- [SEC][CORE] Roles: admin / chofer / mecánico / analista + Pundit policies por recurso
- [CORE] `PaperTrail` — auditoría: quién (user_id), qué cambió, cuándo, desde qué módulo
- [SEC] `secure_headers` gem — CSP, HSTS, X-Frame-Options
- [SEC] `config.force_ssl = true` en producción
- [SEC] `config.filter_parameters` — filtrar :password, :token, :rut, :license_number en logs
- [CORE] Seeds: usuarios demo con cada rol

**Entidades mínimas:** `User(role, nombre, email)`, `AuditLog`

**Entrega:** Login + dashboard por rol + acciones auditadas

---

## ✅ Sprint 1 — Core de la Flota · COMPLETADO

### 1.1 Modelos base
- [CORE] `Vehicle` (patente, modelo, año, odómetro, horas_motor, estado)
- [CORE] `VehicleAssignment` (vehicle_id, user_id/chofer, desde, hasta)
- [CORE] `VehicleDocument` (vehicle_id, tipo, vence_el, archivo)
- [SEC][CORE] CRUD vehículos para admin con Pundit + auditoría PaperTrail
- [UX][CORE] Vista "mi unidad" para chofer — diseño mobile-first

**Entrega:** CRUD de vehículos (admin), vista de unidad (chofer), documentos por rol

---

## ✅ Sprint 2 — Checklists Pre-operativos · COMPLETADO

### 2.1 Plantillas de checklist
- [CORE] `ChecklistTemplate` + `ChecklistItem` (boolean / texto / número / foto requerida)
- Admin define plantillas por tipo de unidad o general

### 2.2 Ejecución (chofer)
- [UX][PWA] `Turbo Frames` en checklist del día — sin recargar página completa
- [SEC][CORE] Firma/confirmación del chofer + estado auditable
- Checklist obligatorio antes de iniciar turno

### 2.3 Revisión (admin)
- [CORE] Vista para validar / observar / rechazar checklist
- Registro de trazabilidad completo

**Entidades:** `ChecklistTemplate`, `ChecklistItem`, `ChecklistSubmission`, `ChecklistAnswer`

**Entrega:** Chofer completa checklist, admin audita y queda registro

---

## ✅ Sprint 3 — Evidencias + Incidentes · COMPLETADO

### 3.1 Carga de evidencias
- [CORE] `Active Storage` configurado (local en dev)
- [CORE] `Evidence` polymorphic — adjuntable a checklist, incidente, documento de unidad
- [UX] Preview de imágenes antes de subir (Stimulus controller)
- [SEC][CORE] Validación server-side de tipo y tamaño de archivo

### 3.2 Incidentes en ruta
- [CORE] `Incident` (vehicle_id, reporter_id, tipo, severidad, descripción, fotos, ubicación opcional)
- Flujo: chofer reporta → admin visualiza → deriva a mecánica

**Entidades:** `Evidence (attachable polymorphic)`, `Incident`

**Entrega:** Flujo real — reportar con foto + revisión centralizada

---

## ✅ Sprint 4 — Inventario + Repuestos + Solicitudes · COMPLETADO

### 4.1 Catálogo de repuestos
- [CORE] `Part` (SKU/nombre, unidad de medida, stock, costo)
- [CORE] `PartFitment` — compatibilidad repuesto ↔ vehículo/modelo

### 4.2 Solicitudes de suministros (mecánico)
- [CORE] `SupplyRequest` con estados: borrador → solicitado → aprobado → entregado → cerrado
- [CORE] `StockMovement` — trazabilidad de entradas/salidas, descuento al "entregado"
- [UX][PWA] Tabla con filtros + búsqueda reactiva con Turbo Frame (sin reload)
- [UX] Selección múltiple para acciones en lote

**Entidades:** `Part`, `PartFitment`, `StockMovement`, `SupplyRequest`, `SupplyRequestLine`

**Entrega:** Mecánico pide repuestos válidos para esa unidad

---

## ✅ Sprint 5 — Pautas Técnicas + Órdenes de Trabajo · COMPLETADO

### 5.1 Mantenimiento preventivo
- [CORE] `MaintenancePlan` — por km / horas de motor / fecha
- [CORE] `MaintenanceTaskTemplate` — checklist técnico interno para taller

### 5.2 Ejecución en taller (mecánico)
- [CORE] `WorkOrder` (vehicle_id, plan_id, status)
- [CORE] `WorkOrderTask` + `WorkOrderPartUsage` — mano de obra, repuestos usados, notas, evidencias
- [CORE] Cierre de mantención y registro de próximo vencimiento
- [UX] Visor de PDFs inline para documentos técnicos

**Entidades:** `MaintenancePlan`, `MaintenanceTaskTemplate`, `WorkOrder`, `WorkOrderTask`, `WorkOrderPartUsage`

**Entrega:** Admin planifica, mecánico ejecuta y queda historial completo

---

## ✅ Sprint 6 — Costos + Facturas · COMPLETADO

### 6.1 Control de costos
- [CORE] `Expense` (vehicle_id, categoría, monto, fecha, proveedor)
- Categorías: mantención (OT), compra repuestos, combustible, peajes, seguros, otros
- [CORE] `Invoice` (expense_id, archivo PDF/imagen)

### 6.2 Reportes
- [CORE][UX] Reporte base mensual por unidad con exportación CSV
- [CORE] Paginación con `Pagy` en todas las tablas de reportes

**Entrega:** Vista de costos por unidad y por período

---

## ✅ Sprint 7 — Vencimientos + Alertas · COMPLETADO

### 7.1 Cumplimiento legal
- [CORE] `ComplianceItem` — revisión técnica, seguros, permiso circulación, licencia de chofer
- [CORE][INFRA] `Notification` (user_id, tipo, estado, payload) enviada con Sidekiq
- [UX][CORE] Tablero de vencimientos con semáforo de colores (verde / amarillo / rojo)
- [CORE] Alertas configurables por proximidad (30 / 15 / 7 días)

**Entidades:** `ComplianceItem`, `Notification`

**Entrega:** Tablero de vencimientos + alertas por proximidad

---

## ✅ Sprint 8 — Combustible + Eficiencia · COMPLETADO

### 8.1 Registro de cargas (chofer)
- [CORE] `FuelFill` (vehicle_id, chofer_id, litros, costo, odómetro, foto ticket)
- [CORE] Cálculo km/litro automático por delta de odómetros

### 8.2 Alertas de desviación
- [CORE] Regla: consumo > promedio + umbral configurable
- Señales: posible falla mecánica / robo / conducción agresiva
- [CORE] KPI de combustible por unidad y por flota (`FuelKPI`)

**Entidades:** `FuelFill`, `FuelKPI`

**Entrega:** Flujo completo de combustible con métricas y alerta básica

---

## ✅ Sprint 9 — Auxilio en Ruta · COMPLETADO

> Este sprint es el momento natural para implementar la PWA completa,
> ya que el botón de emergencia requiere notificaciones push y acceso rápido desde móvil.

### 9.1 Botón de emergencia (chofer)
- [UX][PWA] Botón de emergencia prominente en vista móvil del chofer (acceso rápido desde dashboard)
- [CORE] `RoadsideAssistanceEvent` (vehicle_id, chofer_id, lat, lon, timestamp, fotos, descripción, status)
- [CORE] Estados: solicitado → en camino → resuelto + trazabilidad completa
- [UX][CORE] Vista de seguimiento en tiempo real para mecánico/admin
- [PWA][INFRA] Notificación push al admin al crear evento (Web Push API)

**Entidad:** `RoadsideAssistanceEvent`

### 9.2 Implementación PWA (hacer en este sprint)

**manifest.json:**
```json
{
  "name": "GestiónFlota",
  "short_name": "Flota",
  "start_url": "/dashboard",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#1e40af",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

**Checklist PWA:**
- [PWA] `manifest.json` completo con íconos 192/512px, theme_color, start_url
- [PWA] Service Worker con Workbox — cacheo de App Shell y assets estáticos
- [PWA] Modo offline parcial: formularios en cola, checklists cacheados
- [PWA] Notificaciones push (Web Push API) para alertas de auxilio
- [SEC][INFRA] HTTPS con Let's Encrypt en servidor de producción
- [PWA] Lighthouse PWA audit ≥ 90

**Entrega:** End-to-end: botón de emergencia → ubicación → seguimiento + app instalable

---

## 🔵 Sprint 10+ — Inteligencia de Datos · SIGUIENTE

### 10.1 Dashboards y reportes
- [CORE][UX] KPIs: fallas recurrentes por unidad, costo por km, tiempos muertos, eficiencia flota
- [CORE] Export PDF de reportes con `caxlsx`
- [UX] Gráficos interactivos con Stimulus + Chart.js o Chartkick

### 10.2 Análisis de aceite (predictivo)
- [CORE] `OilAnalysis` (vehicle_id, fecha, métricas, archivo)
- Reglas: umbrales de metales, viscosidad, contaminación → señal "riesgo alto"

### 10.3 Neumáticos
- [CORE] `Tire` (serial, estado) + `TireInstallation` + `TireInspection`
- Trazabilidad por número de serie + posición + profundidad de surco + semáforo de alertas

**Entrega:** Módulo analítico con alertas y reportes estratégicos

---

## 🔄 Transversal — Frontend + UX (todos los sprints)

> Implementar progresivamente en cada sprint. No necesitan sprint propio.

### UX / Frontend
- [UX] Dark mode con Tailwind `dark:` — crítico para uso prolongado
- [UX] Breadcrumbs en todas las vistas internas para no perder contexto
- [UX] Búsqueda global accesible desde cualquier pantalla
- [UX][PWA] Tablas: scroll horizontal en móvil + columnas fijas
- [UX] Datepicker con inputs nativos + máscaras de input (RUT, patente) con `stimulus-mask`
- [UX][SEC] Confirmación modal para acciones destructivas (eliminar, rechazar)
- [UX] Flash messages con auto-dismiss + undo en operaciones críticas
- [UX][PWA] Loaders y skeleton screens en carga de tablas pesadas
- [UX] Autoguardado (draft) en formularios largos de OT y checklist
- [UX] Paleta: base neutra (grises) + 1 color de acción (azul) + rojo solo para alertas/eliminar

### Infraestructura / Servidor
- [INFRA][SEC] Redis para sesiones + caché de consultas frecuentes
- [INFRA] Sidekiq para background jobs: alertas, emails, exports pesados
- [INFRA] Sentry para monitoreo de errores en producción (plan gratuito disponible)
- [INFRA][SEC] Backups automáticos de DB — mínimo diarios
- [INFRA] Deploy con Kamal (herramienta oficial Rails para servidores propios)
- [SEC][INFRA] Variables de entorno con Rails credentials — nunca hardcodear claves
- [SEC] Nunca desactivar `protect_from_forgery` (CSRF)
- [SEC] Usar siempre Active Record con parámetros, nunca interpolación de strings (SQL injection)

### Multi-empresa (según roadmap arquitectónico)
- [CORE][SEC] Modelo `Company` como entidad raíz
- [CORE][SEC] Row-level multitenancy con `CurrentAttributes` + `default_scope`
- [CORE] Configuración por empresa (JSON flags): módulos activos, roles presentes
- [CORE] Lógica de fallback por rol: empresa sin mecánico → responsabilidades al admin/chofer

---

## Gems recomendadas por categoría

| Gem | Categoría | Para qué sirve |
|---|---|---|
| `devise` | SEC | Autenticación base |
| `devise-two-factor` | SEC | 2FA con TOTP |
| `rack-attack` | SEC | Rate limiting y bloqueo de IPs |
| `pwned` | SEC | Verificar contraseñas filtradas en brechas |
| `devise-security` | SEC | Expiración de contraseñas, historial, complejidad |
| `pundit` | SEC | Autorización por recurso y rol |
| `paper_trail` | SEC | Auditoría completa de cambios |
| `secure_headers` | SEC | CSP, HSTS, X-Frame-Options |
| `pagy` | CORE | Paginación rápida |
| `sidekiq` | INFRA | Background jobs |
| `redis` | INFRA | Caché + sesiones |
| `sentry-ruby` | INFRA | Monitoreo de errores |
| `caxlsx` | CORE | Export Excel/PDF |

---

## Orden de desarrollo recomendado (resumen)

1. ✅ Auth + Roles + Auditoría
2. ✅ Vehículos + Documentos
3. ✅ Checklists + Auditoría de inspecciones
4. ✅ Evidencias + Incidentes
5. ✅ Inventario + Repuestos + Solicitudes
6. ✅ Pautas + Órdenes de trabajo
7. ✅ Costos + Facturas
8. ✅ Vencimientos + Alertas
9. ✅ Combustible + Eficiencia
10. ✅ Auxilio en ruta **+ implementación PWA completa**
11. 🔵 Analítica avanzada: dashboards, aceite, neumáticos

---

## Entregables mínimos por módulo

- Rutas / Controllers + Views por rol
- Policies (Pundit) por recurso
- Auditoría (PaperTrail) en modelos críticos
- Seeds + datos demo
- Tests básicos (model + request) por flujo crítico
