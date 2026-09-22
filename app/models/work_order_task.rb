class WorkOrderTask < ApplicationRecord
  belongs_to :work_order

  validates :description, presence: true
end
