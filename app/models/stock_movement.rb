class StockMovement < ApplicationRecord
  belongs_to :part

  enum :movement_type, { in: 0, out: 1, adjustment: 2 }
  validates :quantity, presence: true
end
