class MaintenanceTaskTemplate < ApplicationRecord
  belongs_to :maintenance_plan
  belongs_to :maintenance_task, optional: true

  validates :description, presence: true
  
  default_scope { order(:position) }
end
