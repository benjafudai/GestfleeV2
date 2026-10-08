# Repuesto que lleva una tarea en un modelo, con precio de referencia neto en
# CLP. price_type dice si el precio se verificó en una tienda o es estimado.
class VehicleModelPart < ApplicationRecord
  PRICE_TYPES = %w[verificado estimado].freeze

  belongs_to :vehicle_model
  belongs_to :maintenance_task

  validates :code, presence: true, uniqueness: true
  validates :description, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price_net_clp, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_type, inclusion: { in: PRICE_TYPES }, allow_nil: true
end
