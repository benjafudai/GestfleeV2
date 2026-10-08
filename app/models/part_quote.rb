# Precio que un proveedor le dio a la empresa por un repuesto. El historial
# sirve para comparar proveedores y ver cómo cambia el precio en el tiempo.
class PartQuote < ApplicationRecord
  include CompanyScoped

  belongs_to :part
  belongs_to :user, optional: true

  validates :supplier, :quoted_on, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :currency, inclusion: { in: %w[CLP USD] }
  validates :url, format: { with: %r{\Ahttps?://}i, message: "debe empezar con http:// o https://" }, allow_blank: true
  validate :part_must_match_company

  scope :recent_first, -> { order(quoted_on: :desc, created_at: :desc) }

  def price_in_clp
    currency == "USD" ? price * CurrencyConverter.usd_to_clp : price
  end

  private

  # La empresa se toma del repuesto, con Current.company solo como respaldo.
  def assign_company
    self.company ||= part&.company || Current.company
  end

  def part_must_match_company
    return unless part && company
    errors.add(:part, "debe pertenecer a la misma empresa") if part.company_id != company_id
  end
end
