# Revisión funcional por rol — hallazgos y correcciones

Auditoría "ultra detallista" de funcionalidad, rol por rol, iniciada 2026-09-22.
Foco exclusivo en funcionalidad (bugs reales) — lo visual/diseño queda para una
pasada aparte, después de terminar los 5 roles.

**Estado:** Chofer ✅ · Mecánico ✅ · Analista ✅ · Admin ⬜ · Superadmin ⬜

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

## Próximos roles

- **Admin** — el rol más grande (casi todo el sistema); buen momento para
  revisar el bug pendiente de `Company#destroy`.
- **Superadmin** — gestión de empresas/usuarios entre tenants; revisar con
  cuidado que el aislamiento entre empresas siga la regla "ve todo", no
  "ve nada" (el bug que se repitió en varios modelos esta semana).
