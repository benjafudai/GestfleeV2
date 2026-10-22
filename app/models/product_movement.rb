# Entrada, salida o ajuste del stock de un producto. Guarda el stock con que quedó.
class ProductMovement < ApplicationRecord
  belongs_to :product
  belongs_to :user, optional: true
  belongs_to :delivery, optional: true

  # Ajuste: la cantidad es el stock contado, que reemplaza al anterior.
  enum :kind, { entry: 0, withdrawal: 1, adjustment: 2 }, validate: true

  KIND_LABELS = { "entry" => "Entrada", "withdrawal" => "Salida", "adjustment" => "Ajuste" }.freeze

  validates :quantity, numericality: { greater_than: 0 }, unless: :adjustment?
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, if: :adjustment?
  validates :note, length: { maximum: 255 }

  # Guarda el movimiento y actualiza el stock del producto en una sola transacción.
  # Devuelve false (con el error en el movimiento) si una salida deja el stock bajo cero.
  def apply
    return false unless valid?

    transaction do
      product.lock!
      new_stock = stock_for(product.stock)
      if new_stock.negative?
        available = ActiveSupport::NumberHelper.number_to_rounded(product.stock, precision: 3, strip_insignificant_zeros: true,
                                                                                  separator: ",", delimiter: ".")
        errors.add(:quantity, "es mayor que el stock disponible (#{available} #{product.unit})")
        raise ActiveRecord::Rollback
      end
      self.stock_after = new_stock
      product.update!(stock: new_stock)
      save!
    end
    persisted?
  end

  def kind_label
    KIND_LABELS[kind]
  end

  private

  def stock_for(current)
    case kind
    when "entry" then current + quantity
    when "withdrawal" then current - quantity
    else quantity
    end
  end
end
