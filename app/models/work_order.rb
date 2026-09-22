class WorkOrder < ApplicationRecord
  include CompanyScoped

  belongs_to :vehicle
  belongs_to :maintenance_plan, optional: true
  belongs_to :mechanic, class_name: 'User', optional: true

  has_many :work_order_tasks, dependent: :destroy
  has_many :work_order_part_usages, dependent: :destroy

  accepts_nested_attributes_for :work_order_tasks, allow_destroy: true
  accepts_nested_attributes_for :work_order_part_usages, allow_destroy: true

  enum status: { pending: 0, in_progress: 1, completed: 2, cancelled: 3 }

  TERMINAL_STATUSES = %w[completed cancelled].freeze

  validate :mechanic_must_belong_to_same_company
  validate :immutable_once_terminal, on: :update
  validate :sufficient_stock_to_complete, if: -> { status == 'completed' && status_changed? }

  after_save :deduct_stock, if: -> { saved_change_to_status? && status == 'completed' }

  private

  def mechanic_must_belong_to_same_company
    return unless mechanic
    errors.add(:mechanic, "debe pertenecer a la misma empresa") if mechanic.company_id != company_id
  end

  def immutable_once_terminal
    return unless TERMINAL_STATUSES.include?(status_was)
    errors.add(:base, "no se puede modificar una orden de trabajo ya #{status_was == 'completed' ? 'completada' : 'cancelada'}")
  end

  def sufficient_stock_to_complete
    work_order_part_usages.reject(&:marked_for_destruction?).each do |usage|
      next unless usage.part
      if usage.part.stock < usage.quantity
        errors.add(:base, "Stock insuficiente de #{usage.part.name} (disponible: #{usage.part.stock}, se necesita: #{usage.quantity})")
      end
    end
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
