# Tarea de mantención de la biblioteca común (TR-01 "Cambio de aceite de
# motor y filtro"), con su paso a paso, herramientas y EPP.
class MaintenanceTask < ApplicationRecord
  has_many :steps, -> { order(:position) }, class_name: "MaintenanceTaskStep", dependent: :destroy
  has_many :plan_items, class_name: "VehicleModelPlanItem", dependent: :restrict_with_error
  has_many :parts, class_name: "VehicleModelPart", dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
