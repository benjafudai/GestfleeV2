# Roadmap de Implementación (Rails) — Sistema de Gestión de Flota

> Objetivo: centralizar operación, gestión, análisis y ejecución técnica/operativa,
> con máxima trazabilidad y eficiencia, basado en roles: Admin (Azul), Chofer (Naranjo),
> Mecánico (Rojo), Analista (Amarillo).  (ver PDF)

---

## 0) Fundaciones (Sprint 0) — “Que la app sea construible”
### 0.1 Setup técnico
- Crear app Rails (PostgreSQL)
- Configurar Tailwind/Bootstrap (UI) + layout base
- Configurar i18n (es-CL) y zonas horarias
- CI básico (tests + lint opcional)

### 0.2 Autenticación + Roles + Trazabilidad (imprescindible)
- Devise (o auth equivalente)
- Roles: admin / chofer / mecanico / analista
- Autorización: Pundit (policies por recurso)
- Auditoría: PaperTrail (o Audited)
  - Registrar: quién (user_id), qué cambió, cuándo, y desde qué módulo
- Seeds: usuarios demo y roles

**Entidades mínimas**
- User(role, nombre, email, …)
- AuditLog (si no usas PaperTrail, tabla propia)

**Entrega Sprint 0**
- Login + dashboard por rol + acciones auditadas

---

## 1) Core de la flota (Sprint 1) — “Todo cuelga de las unidades”
### 1.1 Modelos base
- Unidad/Vehículo (camión)
- Chofer (si no es User directamente)
- Mecánico (si no es User directamente)
- Asignación chofer ↔ unidad (opcional: por turnos/fechas)
- Catálogo de Documentos por Unidad (tipo, vencimiento, archivo)

**Entidades**
- Vehicle (patente, modelo, año, odómetro, horas_motor?, estado)
- VehicleAssignment (vehicle_id, user_id(chofer), desde, hasta)
- VehicleDocument (vehicle_id, tipo, vence_el, archivo)

**Entrega Sprint 1**
- CRUD de vehículos (admin)
- Vista de “mi unidad” (chofer)
- Documentos visibles según rol

---

## 2) Checklists pre-operativos + Auditoría de inspecciones (Sprint 2)
### 2.1 Plantillas de checklist
- Admin define plantillas (por tipo de unidad o general)
- Items con tipo: boolean / texto / número / foto requerida

### 2.2 Ejecución del checklist (chofer)
- “Checklist del día” obligatorio antes de iniciar
- Firma/confirmación
- Envío para revisión/admin (auditoría de inspecciones)

### 2.3 Revisión (admin)
- Validar / observar / rechazar checklist
- Registro de trazabilidad

**Entidades**
- ChecklistTemplate
- ChecklistItem
- ChecklistSubmission (vehicle_id, chofer_id, fecha, estado)
- ChecklistAnswer (submission_id, item_id, valor)

**Entrega Sprint 2**
- Chofer completa checklist
- Admin audita y queda registro

---

## 3) Evidencias (fotos) + Incidentes (Sprint 3)
### 3.1 Carga de evidencias
- ActiveStorage (local/dev + S3 en prod)
- Evidencia asociada a:
  - checklist submission
  - incidente
  - documento/estado general de unidad

### 3.2 Incidentes en ruta / estado vehículo
- Chofer reporta incidente con:
  - tipo, descripción, severidad, fotos, ubicación opcional
- Admin visualiza y deriva a mecánica

**Entidades**
- Evidence (attachable polymorphic)
- Incident (vehicle_id, reporter_id, status, descripcion, severidad)

**Entrega Sprint 3**
- Flujo real: reportar con foto + revisión centralizada

---

## 4) Inventario + Repuestos por máquina + Solicitudes (Sprint 4)
### 4.1 Catálogo de repuestos (admin)
- Repuesto (SKU/nombre), unidad de medida, stock, costo
- Compatibilidad: repuesto ↔ vehículo/modelo (base “por máquina”)

### 4.2 Solicitudes de suministros (mecánico)
- Crear solicitud asociada a vehículo y trabajo
- Estados: borrador → solicitado → aprobado → entregado → cerrado
- Descuento de stock al “entregado”

**Entidades**
- Part (repuesto)
- PartFitment (part_id, vehicle_id o vehicle_model_id)
- StockMovement
- SupplyRequest + SupplyRequestLine

**Entrega Sprint 4**
- Mecánico pide repuestos “válidos” para esa unidad

---

## 5) Pautas técnicas y mantenciones (Sprint 5)
### 5.1 Pautas de mantenimiento preventivo (admin)
- Plan por unidad: por km / por horas de motor / por fecha
- Checklist técnico interno para el taller (mecánico)

### 5.2 Ejecución en taller (mecánico)
- Orden de trabajo (OT)
- Registrar mano de obra, repuestos usados, notas, evidencias
- Cierre de mantención y próximo vencimiento

**Entidades**
- MaintenancePlan
- MaintenanceTaskTemplate
- WorkOrder (vehicle_id, plan_id, status)
- WorkOrderTask + WorkOrderPartUsage

**Entrega Sprint 5**
- Admin planifica, mecánico ejecuta y queda historial

---

## 6) Costos + Facturas + Documentación administrativa (Sprint 6)
### 6.1 Control de costos (admin)
- Registro de egresos por:
  - mantención (OT)
  - compra repuestos
  - combustible (si aplica)
  - otros (peajes, seguros, etc.)

### 6.2 Facturas y registros
- Adjuntar documentos (PDF/imagen) a gastos
- Reporte base mensual por unidad

**Entidades**
- Expense (vehicle_id, categoria, monto, fecha, proveedor)
- Invoice (expense_id, archivo)

**Entrega Sprint 6**
- Vista de costos por unidad y por período

---

## 7) Vencimientos legales y seguros + Alertas (Sprint 7)
### 7.1 Alertas de cumplimiento (admin)
- Revisión técnica, seguros, permiso circulación, etc.
- Licencia de chofer (vencimiento) (si tienes entidad chofer)
- Notificaciones (correo / in-app)

**Entidades**
- ComplianceItem (type, due_date, vehicle_id o user_id)
- Notification (user_id, tipo, estado, payload)

**Entrega Sprint 7**
- Tablero de vencimientos + alertas por proximidad

---

## 8) Combustible y eficiencia (Sprint 8)
### 8.1 Registro de cargas (chofer)
- Subir ticket (foto) + litros + costo + odómetro
- Calcular km/litro (según odómetro o delta de cargas)

### 8.2 Alertas de desviación (analítica/admin)
- Regla simple: consumo > promedio + umbral
- Marcar posible: falla mecánica / robo / conducción agresiva

**Entidades**
- FuelFill (vehicle_id, chofer_id, litros, costo, odometro, evidencia)
- FuelKPI (materialized o query)

**Entrega Sprint 8**
- Flujo completo de combustible con métrica y alerta básica

---

## 9) Auxilio en ruta (Sprint 9)
### 9.1 Botón de emergencia (chofer)
- Crear “evento de auxilio” con:
  - ubicación (lat/lon), timestamp, fotos, descripción
- Admin recibe en tablero (y opcional notificación)
- Mecánico ve el caso y prepara salida (adjuntos)

**Entidades**
- RoadsideAssistanceEvent (vehicle_id, chofer_id, status, location)

**Entrega Sprint 9**
- End-to-end: botón → ubicación → seguimiento

---

## 10) Inteligencia de datos (Sprint 10+)
### 10.1 Dashboards y reportes
- KPIs: fallas recurrentes por unidad, costos por km, tiempos muertos, etc.
- Export CSV/PDF

### 10.2 Aceite (predictivo)
- Cargar resultado de análisis de aceite por unidad
- Reglas iniciales: umbrales (metales, viscosidad, contaminación)
- Señales: “riesgo alto” + recomendación

### 10.3 Neumáticos (si lo incluyes)
- Trazabilidad por número de serie + posición
- Profundidad de surco + semáforo de alertas

**Entidades**
- OilAnalysis (vehicle_id, fecha, métricas, archivo)
- Tire (serial, estado) + TireInstallations + TireInspection

**Entrega Sprint 10+**
- Módulo analítico con alertas y reportes estratégicos

---

# Orden recomendado de desarrollo (resumen)
1) Auth + Roles + Auditoría
2) Vehículos + Documentos
3) Checklists + Auditoría de inspecciones
4) Evidencias + Incidentes
5) Inventario + Repuestos por máquina + Solicitudes
6) Pautas + Órdenes de trabajo
7) Costos + Facturas
8) Vencimientos + Alertas
9) Combustible + Eficiencia
10) Auxilio en ruta
11) Analítica avanzada: aceite / fallas / neumáticos / telemetría

---

# Entregables por módulo (mínimo viable)
- Rutas/Controllers + Views por rol
- Policies (Pundit)
- Auditoría (PaperTrail)
- Seeds + datos demo
- Tests básicos (model + request) por flujo crítico

---

# Actualización de Arquitectura y Reglas de Negocio (Post-Sprint 0)

## A. Estrategia Móvil y Multi-Empresa
1. **Móvil**: Uso de **Turbo Native** (iOS/Android) para envolver la aplicación Rails.
   - Reutilización del 100% de la lógica y vistas.
   - Navegación nativa + Notificaciones Push.
2. **Multi-Empresa**: Aislamiento lógico de datos (Row-level Multitenancy).
   - Modelo `Company` como entidad raíz.
   - `User`, `Vehicle`, y futuros recursos pertenecen a `Company`.
   - `CurrentAttributes` + `default_scope` para garantizar aislamiento automático.

## B. Configurabilidad de Roles por Empresa
Dado que las empresas varían en tamaño, el sistema debe ser flexible en la asignación de responsabilidades.

1. **Configuración de Empresa**: 
   - Se añadirá un campo de configuración (JSON o flags) en el modelo `Company` para definir qué módulos/roles están activos.
   - *Ejemplos*: "Full Suite", "Sin Mecánico", "Solo Choferes + Admin".

2. **Delegación de Responsabilidades (Logica de Fallback)**:
   - **Caso: Empresa sin Mecánico**:
     - Las responsabilidades del mecánico (ej. revisar checklist técnico, aprobar reparaciones menores) se delegan al **Chofer** (autocontrol) o al **Admin**, según la política configurada.
     - La UI debe adaptarse: si no hay mecánico, el botón "Enviar a Taller" podría cambiar a "Registrar Reparación Propia" o "Notificar a Admin".
   - **Caso: Empresa sin Analista**:
     - Las funciones de monitoreo de KPIs y alertas recaen en el **Admin** de la empresa.
