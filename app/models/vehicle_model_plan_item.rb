# Qué tarea se le hace a un modelo y cada cuánto: frequency_value en km, horas
# o días, con frequency_months como límite por tiempo (lo que ocurra primero).
class VehicleModelPlanItem < ApplicationRecord
  FREQUENCY_UNITS = %w[km horas dias].freeze

  belongs_to :vehicle_model
  belongs_to :maintenance_task

  validates :code, presence: true, uniqueness: true
  validates :frequency_value, numericality: { only_integer: true, greater_than: 0 }
  validates :frequency_unit, inclusion: { in: FREQUENCY_UNITS }
  validates :frequency_months, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
