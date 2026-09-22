class WorkOrderPartUsage < ApplicationRecord
  belongs_to :work_order
  belongs_to :part

  validates :quantity, numericality: { greater_than: 0 }
  validate :part_must_belong_to_same_company

  private

  def part_must_belong_to_same_company
    return unless part && work_order
    errors.add(:part, "debe pertenecer a tu empresa") if part.company_id != work_order.company_id
  end
end
