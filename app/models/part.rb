class Part < ApplicationRecord
  include CompanyScoped

  has_many :part_fitments, dependent: :destroy
  has_many :vehicles, through: :part_fitments
  has_many :stock_movements, dependent: :destroy
  has_many :work_order_part_usages, dependent: :destroy
  has_many :supply_request_lines, dependent: :destroy

  validates :sku, :name, :unit_of_measure, presence: true
  validates :sku, uniqueness: { scope: :company_id }
  validates :currency, inclusion: { in: %w[CLP USD] }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
end
