class MaintenanceTaskStep < ApplicationRecord
  belongs_to :maintenance_task

  validates :position, presence: true, uniqueness: { scope: :maintenance_task_id }
  validates :description, presence: true
end
