# Crea en la empresa del vehículo los planes de mantención y los repuestos que
# la biblioteca común define para su modelo. Agrupa las líneas del plan por
# frecuencia ("cada 10.000 km o 6 meses") y deja cada repuesto marcado como
# compatible con el vehículo. Se puede repetir: no duplica planes ni repuestos
# y no toca lo que la empresa ya editó.
class VehiclePlanGenerator
  DAYS_PER_MONTH = 30

  Result = Struct.new(:plans_created, :parts_created, :fitments_created, keyword_init: true)

  def initialize(vehicle)
    @vehicle = vehicle
    @model = vehicle.vehicle_model
    @company = vehicle.company
  end

  def call
    raise ArgumentError, "El vehículo no tiene modelo de la biblioteca" unless @model

    result = Result.new(plans_created: 0, parts_created: 0, fitments_created: 0)
    ActiveRecord::Base.transaction do
      create_plans(result)
      create_parts(result)
    end
    result
  end

  private

  def create_plans(result)
    groups = @model.plan_items.includes(:maintenance_task).order(:id)
                   .group_by { |item| [item.frequency_unit, item.frequency_value, item.frequency_months] }

    groups.each do |(unit, value, months), items|
      plan = MaintenancePlan.unscoped.find_or_initialize_by(company: @company, vehicle_model: @model, name: plan_name(unit, value, months))
      next if plan.persisted?

      plan.assign_attributes(intervals(unit, value, months))
      plan.description = "Creado desde la biblioteca (#{@model.code}). Se hace lo que ocurra primero."
      items.each.with_index(1) do |item, position|
        plan.maintenance_task_templates.build(
          maintenance_task: item.maintenance_task, position: position,
          description: [item.action, item.maintenance_task.name].compact_blank.join(": ") + (item.note.present? ? " (#{item.note})" : ""),
          expected_duration_minutes: item.maintenance_task.estimated_hours&.*(60)&.round
        )
      end
      plan.save!
      result.plans_created += 1
    end
  end

  def create_parts(result)
    @model.parts.order(:code).each do |library_part|
      part = Part.unscoped.find_or_initialize_by(company: @company, sku: library_part.code)
      if part.new_record?
        part.update!(
          name: [library_part.description, library_part.specification].compact_blank.join(" · "),
          unit_of_measure: library_part.unit.presence || "un",
          cost: library_part.unit_price_net_clp || 0, currency: "CLP", stock: 0
        )
        result.parts_created += 1
      end

      fitment = PartFitment.unscoped.find_or_initialize_by(company: @company, part: part, vehicle: @vehicle)
      next if fitment.persisted?

      fitment.save!
      result.fitments_created += 1
    end
  end

  def plan_name(unit, value, months)
    every = case unit
            when "km" then "#{ActiveSupport::NumberHelper.number_to_delimited(value, delimiter: '.')} km"
            when "horas" then "#{ActiveSupport::NumberHelper.number_to_delimited(value, delimiter: '.')} h"
            else value == 1 ? "día" : "#{value} días"
            end
    limit = months.present? && unit != "dias" ? " o #{months} #{months == 1 ? 'mes' : 'meses'}" : ""
    "#{@model.name} · cada #{every}#{limit}"
  end

  def intervals(unit, value, months)
    {
      interval_km: (value if unit == "km"),
      interval_hours: (value if unit == "horas"),
      interval_days: unit == "dias" ? value : months&.*(DAYS_PER_MONTH)
    }
  end
end
