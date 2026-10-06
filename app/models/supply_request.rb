class SupplyRequest < ApplicationRecord
  include CompanyScoped

  belongs_to :vehicle
  belongs_to :user
  has_many :supply_request_lines, dependent: :destroy
  accepts_nested_attributes_for :supply_request_lines, allow_destroy: true

  enum :status, { requested: 0, received: 1, purchasing: 2, delivered: 3 }

  STATUS_LABELS = {
    "requested" => "Solicitado",
    "received" => "Recibido",
    "purchasing" => "Comprando",
    "delivered" => "Entregado"
  }.freeze

  def self.human_status(status)
    STATUS_LABELS[status.to_s] || status.to_s.humanize
  end

  validate :immutable_once_delivered, on: :update
  validate :sufficient_stock_to_deliver, if: -> { status == 'delivered' && status_changed? }

  after_update :process_stock_delivery, if: -> { saved_change_to_status? && delivered? }

  private

  def sufficient_stock_to_deliver
    supply_request_lines.reject(&:marked_for_destruction?).each do |line|
      next unless line.part
      if line.part.stock < line.quantity
        errors.add(:base, "Stock insuficiente de #{line.part.name} (disponible: #{line.part.stock}, se necesita: #{line.quantity})")
      end
    end
  end

  # La empresa se toma del vehículo, con Current.company solo como respaldo.
  def assign_company
    self.company ||= vehicle&.company || Current.company
  end

  def immutable_once_delivered
    errors.add(:base, "no se puede modificar una solicitud ya entregada") if status_was == "delivered"
  end

  def process_stock_delivery
    # El mecánico retira repuestos del inventario para usarlos en el vehículo
    # (igual que una Orden de Trabajo): "entregado" consume stock, no lo repone.
    supply_request_lines.each do |line|
      StockMovement.create!(
        part: line.part,
        quantity: -line.quantity,
        movement_type: :out,
        reference: "SupplyRequest ##{id}"
      )

      line.part.with_lock do
        line.part.update!(stock: line.part.stock - line.quantity)
      end
    end
  end
end
