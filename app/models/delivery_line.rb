# Un producto y la cantidad entregada en una entrega.
class DeliveryLine < ApplicationRecord
  belongs_to :delivery, inverse_of: :lines
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validate :product_from_same_company

  private

  def product_from_same_company
    return unless product && delivery

    errors.add(:product, "no pertenece a la empresa") if product.company_id != delivery.company_id
  end
end
