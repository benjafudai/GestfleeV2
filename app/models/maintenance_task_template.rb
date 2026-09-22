class MaintenanceTaskTemplate < ApplicationRecord
  belongs_to :maintenance_plan

  validates :description, presence: true
  
  default_scope { order(:position) }
end
