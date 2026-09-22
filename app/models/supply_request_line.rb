class SupplyRequestLine < ApplicationRecord
  belongs_to :supply_request
  belongs_to :part

  validates :quantity, numericality: { greater_than: 0 }
end
