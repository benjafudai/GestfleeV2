class SupplyRequest < ApplicationRecord
  belongs_to :vehicle
  belongs_to :user
  has_many :supply_request_lines, dependent: :destroy
  accepts_nested_attributes_for :supply_request_lines, allow_destroy: true

  enum status: { requested: 0, received: 1, purchasing: 2, delivered: 3 }

  after_update :process_stock_delivery, if: -> { saved_change_to_status? && delivered? }

  private

  def process_stock_delivery
    supply_request_lines.each do |line|
      StockMovement.create!(
        part: line.part,
        quantity: line.quantity,
        movement_type: :out,
        reference: "SupplyRequest ##{id}"
      )
      
      line.part.with_lock do
        line.part.update!(stock: line.part.stock - line.quantity)
      end
    end
  end
end
