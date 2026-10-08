class Part < ApplicationRecord
  include CompanyScoped

  has_many :part_fitments, dependent: :destroy
  has_many :vehicles, through: :part_fitments
  has_many :stock_movements, dependent: :destroy
  has_many :work_order_part_usages, dependent: :destroy
  has_many :supply_request_lines, dependent: :destroy
  has_many :part_quotes, dependent: :destroy

  validates :sku, :name, :unit_of_measure, presence: true
  validates :sku, uniqueness: { scope: :company_id }
  validates :currency, inclusion: { in: %w[CLP USD] }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }

  # Cotización más barata de los últimos BEST_QUOTE_WINDOW, comparando en CLP.
  BEST_QUOTE_WINDOW = 90.days

  def best_quote
    since = BEST_QUOTE_WINDOW.ago.to_date
    part_quotes.select { |quote| quote.quoted_on >= since }.min_by(&:price_in_clp)
  end
end
