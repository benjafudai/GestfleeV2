class MaintenancePlan < ApplicationRecord
  include CompanyScoped

  has_many :maintenance_task_templates, dependent: :destroy
  has_many :work_orders, dependent: :nullify

  validates :name, presence: true

  accepts_nested_attributes_for :maintenance_task_templates,
    allow_destroy: true,
    reject_if: :all_blank
end
