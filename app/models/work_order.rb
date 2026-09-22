class WorkOrder < ApplicationRecord
  belongs_to :company
  belongs_to :vehicle
  belongs_to :maintenance_plan, optional: true
  belongs_to :mechanic, class_name: 'User', optional: true

  has_many :work_order_tasks, dependent: :destroy
  has_many :work_order_part_usages, dependent: :destroy
  
  accepts_nested_attributes_for :work_order_tasks, allow_destroy: true
  accepts_nested_attributes_for :work_order_part_usages, allow_destroy: true

  enum status: { pending: 0, in_progress: 1, completed: 2, cancelled: 3 }

  default_scope { where(company: Current.company) }
  before_validation :assign_company

  after_save :deduct_stock, if: -> { saved_change_to_status? && status == 'completed' }

  private

  def assign_company
    self.company ||= Current.company
  end

  def deduct_stock
    work_order_part_usages.each do |usage|
      StockMovement.create!(
        part: usage.part,
        quantity: -usage.quantity,
        movement_type: :out,
        reference: "WorkOrder ##{id}"
      )
      
      usage.part.with_lock do
        usage.part.update!(stock: usage.part.stock - usage.quantity)
      end
    end
  end
end
