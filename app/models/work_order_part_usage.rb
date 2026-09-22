class WorkOrderPartUsage < ApplicationRecord
  belongs_to :work_order
  belongs_to :part

  validates :quantity, numericality: { greater_than: 0 }
end
