class MaintenancePlan < ApplicationRecord
  include CompanyScoped

  has_many :maintenance_task_templates, dependent: :destroy
  has_many :work_orders, dependent: :nullify
  belongs_to :vehicle_model, optional: true

  accepts_nested_attributes_for :maintenance_task_templates, allow_destroy: true,
    reject_if: proc { |attrs| attrs['description'].blank? }

  validates :name, presence: true
  validates :interval_km, :interval_days, :interval_hours,
            numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  accepts_nested_attributes_for :maintenance_task_templates,
    allow_destroy: true,
    reject_if: :all_blank
end
