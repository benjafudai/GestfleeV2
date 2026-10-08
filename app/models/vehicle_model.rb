# Modelo de vehículo de la biblioteca común (por ejemplo "Toyota Hilux").
# Es compartido por todas las empresas; cada empresa lo elige en sus vehículos.
class VehicleModel < ApplicationRecord
  METER_UNITS = %w[km horas].freeze

  has_many :vehicles, dependent: :restrict_with_error
  has_many :plan_items, class_name: "VehicleModelPlanItem", dependent: :destroy
  has_many :parts, class_name: "VehicleModelPart", dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :brand, :model, presence: true
  validates :meter_unit, inclusion: { in: METER_UNITS }

  def name
    "#{brand} #{model}"
  end

  # Para los desplegables: "Camioneta · Toyota Hilux".
  def label
    [category, name].compact_blank.join(" · ")
  end
end
