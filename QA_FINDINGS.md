# Revisión funcional por rol — hallazgos y correcciones

Auditoría "ultra detallista" de funcionalidad, rol por rol, iniciada 2026-09-22.
Foco exclusivo en funcionalidad (bugs reales) — lo visual/diseño queda para una
pasada aparte, después de terminar los 5 roles.

**Estado:** Chofer ✅ · Mecánico ✅ · Analista ✅ · Admin ✅ · Superadmin ✅

Los 5 roles quedaron cubiertos por esta auditoría. Queda pendiente la pasada
de diseño/visual (deliberadamente fuera de esta ronda) y el gap arquitectónico
documentado al final de la sección de Superadmin (superadmin no puede crear
recursos de una empresa específica sin tener una empresa "activa").

## Metodología

Por cada rol: 6 revisores (subagentes) en paralelo cubriendo distintos ángulos
(lectura línea por línea, invariantes/permisos faltantes, rastreo entre
vistas y modelos, trampas típicas de Ruby/Rails, reutilización/eficiencia,
profundidad de la solución). Cada hallazgo se re-verifica leyendo el código
real antes de aceptarlo — los agentes se han equivocado al menos dos veces
(ver "Errores propios" más abajo), así que nada se da por bueno sin chequear.
Después de corregir, se prueba en vivo (navegador + scripts contra la base
de datos real) antes de hacer commit.

---

## Rol: Chofer — commit [`15e6d4b`](https://github.com/benjafudai/GestfleeV2/commit/15e6d4b)

### Corregido
- **`Incident` no tenía aislamiento entre empresas** (ni en el modelo ni en
  los permisos) — un admin/mecánico de una empresa veía y editaba
  incidentes de otra. Mismo problema, más leve, en `ChecklistSubmission`
  (ver/aprobar de otra empresa).
- **Un chofer veía el combustible de toda su empresa**, no solo el propio
  — el filtro correcto existía pero nunca se usaba.
- **Cualquiera podía cargar combustible a un vehículo de otra empresa**
  (`FuelFillPolicy#create?`/`new?` estaban en `true` sin condición).
- **`Vehicle` no tenía la relación `has_many :fuel_fills`** — rompía por
  completo la función de combustible por vehículo.
- Un chofer podía crear un incidente y marcarlo "resuelto" él mismo al
  enviarlo, saltándose la revisión.
- El superadmin no podía crear incidentes (crash) ni ver nunca combustible
  (lista siempre vacía) — `Current.company` es `nil` para superadmin y
  nada lo contemplaba.
- Moneda inválida en una carga de combustible rompía todo el guardado
  (error 500) en vez de mostrar un mensaje claro.
- Subir un archivo que no es imagen como evidencia rompía la página al
  mostrarla.
- Si fallaba la validación del checklist, la plantilla elegida se perdía
  silenciosamente.
- Checklist y combustible no exigían que el vehículo fuera el realmente
  asignado al chofer (ya existía esa regla en Incidentes, faltaba acá).
- Código de aislamiento por empresa duplicado en 3 modelos → se extrajo a
  `app/models/concerns/company_scoped.rb` (compartido, nil-safe para
  superadmin) y `app/models/concerns/vehicle_assignable.rb`.

### Decisiones de producto (no bugs, pedidas explícitamente)
- **Auxilio en Ruta se sacó del producto** (nav + rutas eliminadas; el
  código de `roadside_assistance_events_*` queda en el repo sin usar, no
  se borró — "una llamada basta", se retoma más adelante si hace falta).
- Foto de la boleta ahora es **obligatoria siempre** al cargar combustible
  (se sacó el toggle por empresa `require_fuel_ticket`).
- Combustible ahora tiene selector de vehículo para filtrar el historial.

---

## Rol: Mecánico — commit [`3a1c5e0`](https://github.com/benjafudai/GestfleeV2/commit/3a1c5e0)

### Corregido
- **`SupplyRequest` no tenía NINGÚN aislamiento entre empresas** (ni
  siquiera columna `company_id`) — admin/analista de cualquier empresa
  veía, editaba y cambiaba el estado de solicitudes de repuestos de otras
  empresas. Mismo problema en `PartFitment` (compatibilidad repuesto↔
  vehículo filtrada al navegador de cualquiera).
- `WorkOrder`/`Part`/`MaintenancePlan` seguían con el `default_scope`
  viejo (no nil-safe) en vez del concern compartido → superadmin veía
  listas vacías en los tres.
- **El descuento de stock se podía duplicar** alternando el estado de una
  orden de trabajo o solicitud hacia atrás y adelante (sin validación de
  transición). Ahora quedan **inmutables** una vez completada/entregada.
- `Part.stock` no tenía validación de no-negativo; ahora además hay un
  chequeo previo que bloquea completar/entregar con mensaje claro si no
  alcanza el stock, en vez de corromperlo o tirar un error 500.
- Al agregar un repuesto anidado en una OT o solicitud, se podía poner el
  `id` de un repuesto de otra empresa directamente (sin pasar por el
  filtro normal) y descontarle stock a esa empresa.
- El selector de "Mecánico Asignado" mostraba usuarios de todas las
  empresas del sistema.
- `MaintenancePlanPolicy` excluía a mecánico de `index?` aunque el menú sí
  le mostraba el link — ahora puede ver planes, pero solo admin puede
  crear/editar/eliminar (así lo define el roadmap original).
- Las vistas de Solicitudes de Suministro llamaban a
  `SupplyRequest.human_enum_name`, método de una gema (`enum_help`) que no
  está instalada — rompían siempre, al 100%. Reemplazado por un método
  propio `SupplyRequest.human_status`.

### Errores propios (para no repetir)
- Un agente reportó que `SupplyRequest#process_stock_delivery` restaba
  stock cuando "debería sumar" (asumiendo que entregar = reponer
  inventario). Se aceptó ese hallazgo y se corrigió — **estaba mal**.
  `idea.md` (línea 109) dice explícitamente "Descuento de stock al
  'entregado'": una solicitud de suministro es un mecánico retirando
  repuestos del estante para usarlos en un vehículo (consumo, igual
  dirección que `WorkOrder`), no una orden de compra que repone stock. Se
  revirtió antes de comitear. **Lección:** cuando un hallazgo es sobre la
  *dirección* de una regla de negocio (no un crash/bug de seguridad puro),
  verificar contra `idea.md`/`roadmap.md` antes de aceptarlo — los agentes
  detectan inconsistencias pero no conocen la intención real del producto.

### Pendiente para otra ronda (Admin/Superadmin)
- `Company#destroy` sigue roto — ahora falla en `notifications.company_id`
  (la misma familia de bug que `supply_requests`, ya arreglada: `Company`
  tiene `has_many ..., dependent: :destroy` apuntando a una columna que no
  existe). Antes de esa ronda, conviene revisar TODAS las asociaciones de
  `Company` contra `db/schema.rb` de una vez, no ir encontrándolas una por
  una al intentar borrar una empresa de prueba.

---

## Rol: Analista — commit [`e4afe0a`](https://github.com/benjafudai/GestfleeV2/commit/e4afe0a)

### Corregido
- **`FuelFillPolicy` excluía a analista de `index?`/`show?` por completo**
  — el menú le mostraba el link a Combustible pero al entrar le negaba el
  permiso. Además, aunque se arreglara el rol, el `Scope#resolve` caía en
  la rama pensada solo para chofer (`where(user_id: user.id)`, "mis
  propios registros"), que para analista habría quedado siempre vacía.
- **`ExpensePolicy` nunca mencionaba a superadmin** (ni en `index?`, ni en
  `show?`, ni en `Scope#resolve`) — el único rol pensado para ver todo no
  podía ver Costos en ninguna empresa.
- Mismo patrón repetido 3 veces esta semana (mecánico/`MaintenancePlan`,
  analista/`FuelFill`, superadmin/`Expense`): un rol simplemente olvidado
  en una policy. Se agregaron helpers compartidos `same_company?` y
  `Scope#company_scoped` a `ApplicationPolicy` y se migraron
  `FuelFillPolicy`, `SupplyRequestPolicy` y `ExpensePolicy` para usarlos,
  eliminando el `same_company?` duplicado que cada policy reinventaba por
  su cuenta.
- La categoría de un gasto se mostraba en español en el listado pero en
  inglés crudo (`.humanize`) en el detalle — se agregó
  `Expense.human_category`, mismo patrón que `SupplyRequest.human_status`
  de la ronda anterior.
- `Expense.documents` no validaba el tipo de archivo adjunto (todos los
  demás modelos con adjuntos del sistema sí lo hacen) — ahora solo acepta
  imágenes o PDF.
- La fecha en el detalle de un gasto mostraba el mes en inglés (el
  proyecto no tiene `config/locales/es.yml`) — se agregó un helper
  (`long_spanish_date`) para ese caso puntual. El mismo problema existe en
  ~10 vistas más del sistema; queda para la pasada de diseño/i18n en vez
  de parchearlo vista por vista ahora.
- N+1 en `expenses#index` (faltaba `.includes(:vehicle)`) y cálculo de
  totales duplicado (4 consultas donde bastaban 2) en la vista de listado.

### Verificado
- Scripts contra la base real: analista ahora ve y lista `FuelFill` con
  datos reales; superadmin ahora ve y lista `Expense` con datos reales;
  analista sigue sin poder crear/editar nada en ningún lado (se mantiene
  su acceso de solo lectura); `human_category` da las etiquetas correctas;
  adjuntar un `.exe` se rechaza, un `.pdf` se acepta.
- Navegador en vivo (cruzado con logs del servidor): `FuelFillsController
  #index` responde `200 OK` para el usuario analista, sin
  `Pundit::NotAuthorizedError`.

---

## Rol: Admin — commit [`bf7f8de`](https://github.com/benjafudai/GestfleeV2/commit/bf7f8de)

Ronda más grande hasta ahora (Admin administra casi todo el sistema dentro de
su empresa). Metodología: 6 revisores en paralelo + verificación manual
propia de cada hallazgo contra el código real antes de aceptarlo.

### Corregido — seguridad / aislamiento entre empresas
- **`UsersController#destroy` no filtraba por empresa** — cualquier admin
  podía borrar usuarios de OTRA empresa (incluso otro admin o el
  superadmin) con solo pasar un ID por `DELETE`, aunque la UI nunca
  mostrara ese botón para usuarios ajenos. Extraído a `find_scoped_user`,
  reutilizado en `show`/`destroy`.
- **`VehicleAssignment` no validaba que el chofer fuera de la misma
  empresa que el vehículo** — un admin podía asignar (vía POST directo,
  sin pasar por el selector de la UI) un chofer de otra empresa a uno de
  sus vehículos, cruzando datos entre tenants.
- **`Vehicle` y `ChecklistTemplate` seguían con el `default_scope` viejo
  no nil-safe** (`where(company: Current.company)`) en vez del concern
  `CompanyScoped` — lista vacía para superadmin en Flota y en Checklists.

### Corregido — un módulo entero estaba roto
- **`MaintenancePlan` no podía crearse ni editarse, nunca.** Le faltaba
  `accepts_nested_attributes_for :maintenance_task_templates`, aunque el
  controlador lo permitía y el formulario siempre enviaba ese hash (aunque
  el admin no tocara las tareas). Cualquier intento de guardar un plan
  tiraba `ActiveModel::UnknownAttributeError` (500), el 100% de las veces.
  Todo el módulo de Planes de Mantenimiento estaba inutilizable desde que
  se creó.

### Corregido — rol "olvidado" en policies (mismo patrón de rondas
anteriores, 4 módulos más esta vez)
- `VehiclePolicy`, `VehicleDocumentPolicy` y `VehicleAssignmentPolicy`
  nunca mencionaban `superadmin?` — bloqueado de Flota, sus documentos y
  las asignaciones de chofer en cualquier empresa.
- `ChecklistTemplatePolicy` nunca mencionaba `superadmin?`.
- `SupplyRequestPolicy` dejaba a superadmin **ver** una solicitud pero no
  aprobarla/eliminarla/cambiarle el estado.
- `PasswordResetRequestsController` autorizaba a superadmin pero sus 3
  consultas filtraban por `current_user.company_id` (`nil` para
  superadmin) — la bandeja de "Claves" le salía siempre vacía, sin forma
  de ayudar a ningún usuario de ninguna empresa a recuperar su contraseña.

### Corregido — crashes reproducibles (500 en vez de manejo de error)
- Terminar una asignación de vehículo **el mismo día que empezó** (corregir
  un error al toque, caso común) tiraba 500 — `update!` sin manejo de
  error + validación con `<=` en vez de `<`.
- Desactivar el módulo "Mecánico" de una empresa podía tirar
  `PG::ForeignKeyViolation` a mitad del borrado en lote si algún mecánico
  tenía OTs o solicitudes de suministro asignadas, dejando la empresa en
  estado inconsistente (algunos mecánicos borrados, otros no). `User` no
  declaraba `has_many :work_orders`/`:supply_requests`.
- **`Company#destroy` seguía roto** (pendiente desde la ronda de
  Mecánico): `has_many :notifications, dependent: :destroy` apuntaba a
  una columna `company_id` que no existe en `notifications`. Era además
  redundante — las notificaciones ya se borran en cascada vía
  `user.notifications` al borrar los usuarios de la empresa. Se eliminó
  la asociación.
- `Vehicle` no declaraba `has_many :work_orders`/`:supply_requests`/
  `:part_fitments` pese a que esas foreign keys existen sin cascada —
  borrar un vehículo con historial de OTs, solicitudes o compatibilidades
  reventaba con `ActiveRecord::InvalidForeignKey`.
- `User` no declaraba `has_many :fuel_fills` ni
  `:resolved_password_reset_requests` (`admin_id`) — borrar un chofer con
  cargas de combustible, o un admin que resolvió alguna solicitud de
  clave, tiraba la misma `InvalidForeignKey`.
- Un valor de enum inválido (rol, estado, etc.) lanza `ArgumentError` al
  asignarse, antes de correr ninguna validación — 500 crudo confirmado en
  5 controladores distintos. Se agregó `rescue_from ArgumentError`
  centralizado en `ApplicationController` (mismo patrón que el
  `rescue_from` de Pundit ya existente), más `rescue_from
  ActiveRecord::RecordNotFound` para que un ID inválido o de otra empresa
  redirija con un mensaje en vez de mostrar la página de error de Rails.
- `MaintenancePlansController#edit` y `WorkOrdersController#edit` no
  llamaban `authorize` — cualquier usuario autenticado (ej. un chofer)
  podía ver el formulario de edición completo por URL directa, aunque no
  pudiera guardar cambios.

### Corregido — gaps de funcionalidad
- **`UsersController` no tenía `edit`/`update`** (las rutas existían, la
  acción no) — la única forma de corregir un typo o cambiar el rol de
  alguien era borrar y recrear el usuario, perdiendo su historial de
  auditoría (PaperTrail). Se agregaron ambas acciones (sin tocar
  contraseña, que sigue siendo exclusiva del flujo de recuperación) más
  el link "Editar" en el listado.
- `UserDocument` no validaba el tipo de archivo adjunto (único modelo de
  adjuntos de la app sin esa validación) — se sirve luego "inline", riesgo
  de XSS almacenado con un `.html`/`.svg` o simplemente malware.
  Restringido a imagen o PDF, mismo patrón que `Expense`/`VehicleDocument`.
- `VehicleAssignmentsController#new`/`create` usaba
  `current_user.company.users` para listar choferes disponibles —
  `NoMethodError` para superadmin (`company` es `nil`). Cambiado a
  `@vehicle.company.users` (correcto para ambos roles).
- N+1 en el dashboard de Cumplimiento (`AlertsController`): `.joins` sin
  `.includes` en documentos de vehículo/personal.

### Limpieza
- Eliminadas 2 vistas de scaffold nunca usadas (`users/create.html.erb`,
  `users/destroy.html.erb`) y las rutas muertas de `checklist_items` (sin
  controlador — los ítems se gestionan vía nested attributes del
  formulario de plantilla).
- `MaintenancePlanPolicy`/`WorkOrderPolicy` simplificados para usar el
  helper `company_scoped` compartido en vez de reinventar la misma línea.

### Verificado
- Scripts contra la base real: aislamiento entre empresas (asignación de
  vehículo, borrado en cascada de mecánico/vehículo/chofer con historial),
  validación de tipo de archivo en `UserDocument`, plan de mantenimiento
  con tareas anidadas creándose sin error.
- En vivo en el navegador (cruzado con logs del servidor): login como
  admin y como superadmin, edición de usuario con cambio de rol,
  creación de un plan de mantenimiento con tareas desde el formulario real
  (antes 500 garantizado), acceso de superadmin a `/vehicles` (antes
  bloqueado por completo con "No autorizado").

### Gaps documentados, no implementados en esta ronda (fuera de alcance de
"bug", son funcionalidad nueva)
- `PasswordResetRequest` tiene estados `approved`/`rejected` en el enum
  pero el flujo solo usa `pending`→`completed` — no hay forma de
  "rechazar" una solicitud sospechosa, y pedir un reset dos veces crea
  solicitudes `pending` duplicadas sin límite.
- La revisión de un checklist (aprobar/rechazar) y la resolución de un
  incidente no notifican al chofer/reportante — se enteran solo si
  vuelven a mirar el registro manualmente.
- Las notificaciones de vencimiento de documentos (`VehicleDocument`/
  `UserDocument`) no traen link de acción, a diferencia de las de
  `PasswordResetRequest`.

---

## Rol: Superadmin — commit [`0273998`](https://github.com/benjafudai/GestfleeV2/commit/0273998)

Última ronda. Metodología igual a las anteriores: 6 revisores en paralelo +
verificación manual propia (incluye confirmar empíricamente con SQL directo
un hallazgo que sonaba poco creíble, ver el gap documentado al final).

### Hallazgo más grande: superadmin casi no podía navegar el sistema
El menú de navegación solo tenía links a "Empresas" y "Usuarios" — ninguna
otra sección (Vehículos, Checklists, Incidentes, OTs, Mantenimiento,
Inventario, Suministros, Costos, Combustible, Claves) tenía un link, pese a
que las policies ya le daban acceso de lectura a casi todas (corregidas en
rondas anteriores). Un superadmin no tenía forma de descubrir esas secciones
sin escribir la URL a mano — probablemente por eso los dos bugs siguientes
nunca se habían detectado. Agregados todos los links faltantes.

### Corregido — crashes reproducibles
- Abrir "Nuevo Incidente" o "Nueva Orden de Trabajo" como superadmin
  reventaba con `NoMethodError` (`Current.company.vehicles`/`.users` sobre
  `nil`, ya que `Current.company` siempre es `nil` para superadmin).
  Corregido con consultas nil-safe.
- `SupplyRequestPolicy#create?` no incluía a superadmin (el resto de
  acciones de la misma policy sí) — mismo patrón de "rol olvidado" visto
  varias veces en rondas anteriores.

### Corregido — `Company#destroy` y borrado en cascada (siguiente capítulo
del bug que quedó pendiente desde Mecánico y se creía cerrado en Admin)
- **`Part` no declaraba `has_many :stock_movements`/`:work_order_part_usages`/
  `:supply_request_lines`** pese a que esas foreign keys existen sin
  cascada — borrar un repuesto con historial de movimientos o uso en una
  OT/solicitud reventaba con `ActiveRecord::InvalidForeignKey`.
- **`Company` no declaraba `has_many :parts`** — los repuestos de una
  empresa eliminada quedaban huérfanos en la base. Agregado, más
  `has_many` explícito para `:checklist_submissions`/`:part_fitments`/
  `:roadside_assistance_events` (ya cubiertos indirectamente vía `Vehicle`,
  ahora explícitos para no depender de un detalle de otro modelo).
- `Notification` quedaba huérfana al borrar un `FuelFill` o un
  `PasswordResetRequest` con notificaciones asociadas (sin FK real por ser
  polimórfica, mismo problema de fondo). Agregado `has_many :notifications,
  as: :notifiable, dependent: :destroy` en ambos modelos.
- Verificado con un script que crea un registro de CADA tipo (usuarios de
  cada rol, vehículo, asignación, checklist+ítem+envío, incidente,
  combustible, plan+OT, repuesto+movimiento+compatibilidad+uso, solicitud+
  línea, gasto, documentos, solicitud de clave) que `Company#destroy` ya no
  revienta con ningún error de foreign key.

### Corregido — seguridad e integridad de datos
- El rol del usuario administrador inicial al crear una empresa solo se
  forzaba en un hidden field del HTML — un POST directo con
  `company[users_attributes][0][role]=<cualquier rol>` creaba la empresa
  con ese rol en vez de admin. Ahora se fuerza server-side.
- `CompaniesController#update` permitía `users_attributes` en el mismo
  params que "Configurar" — un vector oculto para dar de alta usuarios de
  cualquier rol como efecto colateral de guardar los toggles de módulos.
  Separados los params permitidos de `create`/`update`.
- Editar un usuario a rol "Super Administrador" no limpiaba su
  `company_id` (a diferencia de crear, que sí lo hacía) — podía quedar un
  superadmin atado a una empresa real.
- `Company` no validaba unicidad de RUT — dos empresas con el mismo RUT
  (identificador tributario único en Chile) podían coexistir sin aviso.
- Nada impedía borrar (o reasignar el rol de) el único admin de una
  empresa, dejándola sin nadie que la administre. Agregado un resguardo en
  `UsersController#destroy`/`#update`.
- `CompaniesController#update` guardaba los toggles de módulos y después,
  por separado, borraba mecánicos/analistas sin una transacción atómica
  que cubriera ambos pasos. Envuelto en una transacción.
- Una empresa podía crearse sin ningún usuario si la request omitía por
  completo `users_attributes` (no alcanzable desde la UI normal, sí con un
  POST armado a mano). Agregada validación de presencia `on: :create`.

### Limpieza
- Código de debug (`Rails.logger.debug`, un `console.log` marcado
  literalmente "eliminar después" en el JS de confirmación de borrado) y
  una línea duplicada (`.order(:name)` repetido) en `companies_controller.rb`.
- Eliminada la vista de scaffold sin usar `companies/update.html.erb`.
- `same_company?` duplicado en `IncidentPolicy`/`ChecklistSubmissionPolicy`
  (ya heredado de `ApplicationPolicy`) removido.
- Vestigios del toggle `require_fuel_ticket` (ya removido del producto en
  la ronda de Chofer) limpiados de `Company` y `CompaniesController`.
- `Company` ahora tiene `has_paper_trail` — los cambios a nombre/RUT/
  módulos de una empresa no dejaban ningún rastro de auditoría, pese a ser
  decisiones sensibles que toma justamente el rol dueño del producto.
- Dashboard de superadmin, antes dos tarjetas de navegación sin un solo
  dato, ahora muestra conteo de empresas, usuarios, y alerta si alguna
  empresa quedó sin administrador.
- Buscador de empresas ahora también indexa por RUT (antes solo nombre).

### Verificado
- Scripts contra la base real: cascada completa de `Company#destroy`,
  unicidad de RUT, detección de empresa sin admin, guard del último admin,
  rollback transaccional en `CompaniesController#update`.
- En vivo en el navegador (cruzado con logs del servidor): nav de
  superadmin con todos los links nuevos, `/incidents/new` y
  `/work_orders/new` ya no crashean (antes `NoMethodError` garantizado),
  dashboard con métricas reales.

### Gap arquitectónico documentado, NO corregido esta ronda (requiere una
decisión de producto, no es un fix contenido)
Superadmin no tiene forma de elegir "para qué empresa" está creando un
recurso. El patrón `CompanyScoped#assign_company` (`self.company ||=
Current.company`) funciona para todos los demás roles porque `Current.company`
siempre es su propia empresa — pero para superadmin es siempre `nil`. Esto
significa que **crear** (no solo ver) un `Vehicle`, `ChecklistTemplate`,
`Expense`, `MaintenancePlan`, `Part` o `WorkOrder` como superadmin falla la
validación "La empresa debe existir" — ya corregí que los formularios no
revienten al abrirlos (ver arriba), pero el guardado final seguiría
fallando con un error de validación confuso, salvo en los 3 modelos que ya
derivan la empresa de otra relación (`SupplyRequest`/`PartFitment` del
vehículo, `ChecklistSubmission` también). Opciones para resolverlo de
verdad: (a) agregar un selector de empresa explícito en esos formularios
cuando el usuario es superadmin, o (b) decidir que superadmin no debería
poder crear estos recursos operativos directamente (solo administrar
empresas/usuarios y supervisar en modo lectura), dejando la operación del
día a día a los roles de cada empresa. Es una decisión de producto, no un
bug con una respuesta obvia — queda para cuando el dueño del producto
decida cuál de las dos direcciones tomar.

### Gap técnico documentado, NO corregido esta ronda (requeriría migrar
datos existentes)
`Company#configuration` (columna `jsonb`) usa `store ..., coder: JSON`, que
termina guardando un **string JSON escapado dentro de la columna** en vez
de un objeto real — confirmado directamente con SQL (`jsonb_typeof`
devuelve `'string'`, no `'object'`, apenas se graba cualquier valor
distinto del default `{}`). No rompe nada hoy porque el mismo código
Ruby escribe y lee (el doble-encode/decode se cancela), pero cualquier
query SQL/jsonb directa contra esa columna en el futuro fallaría. Arreglo
correcto: sacar `coder: JSON` y usar `store_accessor` (pensado para
columnas jsonb nativas) en vez de `store` — pero require una migración de
datos para las filas que ya quedaron mal guardadas, fuera de alcance de
esta ronda por el riesgo de romper configuración ya existente sin ese paso.
