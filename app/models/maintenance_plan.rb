class MaintenancePlan < ApplicationRecord
  belongs_to :company
  has_many :maintenance_task_templates, dependent: :destroy
  has_many :work_orders, dependent: :nullify

  validates :name, presence: true

  default_scope { where(company: Current.company) }
  before_validation :assign_company

  private

  def assign_company
    self.company ||= Current.company
  end
end
