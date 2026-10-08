require "csv"

# Carga la biblioteca común desde los CSV de la planilla de planes
# (vehiculos, tareas, pasos, plan, repuestos; separados por ';', UTF-8).
# Se puede correr de nuevo cuando cambie la planilla: actualiza cada fila por
# su código y borra pasos, líneas de plan y repuestos que ya no estén.
class BibliotecaImporter
  class Error < StandardError; end

  FILES = %w[vehiculos tareas pasos plan repuestos].freeze
  DEFAULT_DIR = Rails.root.join("db/biblioteca")

  def initialize(dir = DEFAULT_DIR)
    @dir = Pathname(dir)
  end

  # Devuelve cuántas filas quedaron de cada tipo.
  def call
    missing = FILES.reject { |name| path(name).exist? }
    raise Error, "Faltan archivos en #{@dir}: #{missing.map { |n| "#{n}.csv" }.join(', ')}" if missing.any?

    ActiveRecord::Base.transaction do
      import_vehicle_models
      import_tasks
      import_steps
      import_plan_items
      import_parts
    end

    {
      modelos: VehicleModel.count,
      tareas: MaintenanceTask.count,
      pasos: MaintenanceTaskStep.count,
      plan: VehicleModelPlanItem.count,
      repuestos: VehicleModelPart.count
    }
  end

  private

  def path(name)
    @dir.join("#{name}.csv")
  end

  def rows(name)
    CSV.read(path(name), col_sep: ";", headers: true, encoding: "bom|utf-8").each.with_index(2)
  end

  def import_vehicle_models
    rows("vehiculos").each do |row, line|
      model = VehicleModel.find_or_initialize_by(code: required(row, "id_vehiculo", "vehiculos", line))
      model.update!(
        category: row["categoria"], brand: row["marca"], model: row["modelo"],
        configuration: row["configuracion"], engine: row["motor"], fuel: row["combustible"],
        meter_unit: row["unidad_medicion"].to_s.strip.downcase, base_interval: integer(row["intervalo_base"]),
        typical_use: row["uso_tipico"]
      )
    end
  end

  def import_tasks
    rows("tareas").each do |row, line|
      task = MaintenanceTask.find_or_initialize_by(code: required(row, "id_tarea", "tareas", line))
      task.update!(
        name: row["nombre"], system: row["sistema"], applies_to: row["aplica_a"],
        estimated_hours: decimal(row["tiempo_estimado_h"]), tools: row["herramientas"], ppe: row["epp"]
      )
    end
  end

  def import_steps
    kept = Hash.new { |hash, key| hash[key] = [] }
    rows("pasos").each do |row, line|
      task = task_for(row, "pasos", line)
      position = integer(row["n_paso"])
      step = task.steps.find { |existing| existing.position == position } || task.steps.build(position: position)
      step.update!(description: row["descripcion"])
      kept[task.id] << position
    end
    MaintenanceTaskStep.find_each do |step|
      step.destroy unless kept[step.maintenance_task_id].include?(step.position)
    end
  end

  def import_plan_items
    existing = VehicleModelPlanItem.all.index_by(&:code)
    codes = rows("plan").map do |row, line|
      code = required(row, "id_plan", "plan", line)
      item = existing[code] || VehicleModelPlanItem.new(code: code)
      item.update!(
        vehicle_model: model_for(row, "plan", line), maintenance_task: task_for(row, "plan", line),
        action: row["accion"], frequency_value: integer(row["frecuencia_valor"]),
        frequency_unit: frequency_unit(row["frecuencia_unidad"]),
        frequency_months: integer(row["frecuencia_meses"]), note: row["nota"]
      )
      item.code
    end
    VehicleModelPlanItem.where.not(code: codes).delete_all
  end

  def import_parts
    existing = VehicleModelPart.all.index_by(&:code)
    codes = rows("repuestos").map do |row, line|
      code = required(row, "id_repuesto", "repuestos", line)
      part = existing[code] || VehicleModelPart.new(code: code)
      part.update!(
        vehicle_model: model_for(row, "repuestos", line), maintenance_task: task_for(row, "repuestos", line),
        description: row["descripcion"], specification: row["especificacion"], oem_code: row["codigo_oem"],
        quantity: decimal(row["cantidad"]) || 0, unit: row["unidad"],
        unit_price_net_clp: integer(row["precio_unit_neto_clp"]),
        price_type: row["tipo_precio"].presence&.strip&.downcase
      )
      part.code
    end
    VehicleModelPart.where.not(code: codes).delete_all
  end

  def model_for(row, file, line)
    code = required(row, "id_vehiculo", file, line)
    @models ||= VehicleModel.all.index_by(&:code)
    @models[code] || raise(Error, "#{file}.csv línea #{line}: no existe el vehículo #{code}")
  end

  def task_for(row, file, line)
    code = required(row, "id_tarea", file, line)
    @tasks ||= MaintenanceTask.includes(:steps).index_by(&:code)
    @tasks[code] || raise(Error, "#{file}.csv línea #{line}: no existe la tarea #{code}")
  end

  def required(row, column, file, line)
    row[column].presence&.strip || raise(Error, "#{file}.csv línea #{line}: falta #{column}")
  end

  # Excel en español puede guardar decimales con coma.
  def decimal(value)
    value.present? ? BigDecimal(value.to_s.strip.tr(",", ".")) : nil
  end

  def integer(value)
    decimal(value)&.to_i
  end

  def frequency_unit(value)
    unit = value.to_s.strip.downcase.unicode_normalize(:nfd).gsub(/\p{Mn}/, "")
    { "dia" => "dias", "hora" => "horas", "h" => "horas" }.fetch(unit, unit)
  end
end
