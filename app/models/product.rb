# Producto que la empresa vende o almacena (inventario comercial, aparte de los repuestos).
# El stock se cambia con ProductMovement#apply, no editando el producto.
class Product < ApplicationRecord
  include CompanyScoped

  CURRENCIES = %w[CLP USD].freeze

  has_many :movements, -> { order(created_at: :desc, id: :desc) }, class_name: "ProductMovement", dependent: :delete_all
  has_many :delivery_lines, dependent: :restrict_with_error

  normalizes :code, :category, with: ->(value) { value.strip.presence }
  normalizes :name, :unit, with: ->(value) { value.strip }

  validates :name, :unit, presence: true
  validates :name, length: { maximum: 120 }
  validates :code, :unit, length: { maximum: 40 }
  validates :category, length: { maximum: 60 }
  validates :notes, length: { maximum: 1000 }
  validates :code, uniqueness: { scope: :company_id, allow_nil: true }
  validates :currency, inclusion: { in: CURRENCIES }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :min_stock, :price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  scope :low_stock, -> { where.not(min_stock: nil).where("products.stock <= products.min_stock") }

  def low_stock?
    min_stock.present? && stock <= min_stock
  end
end
