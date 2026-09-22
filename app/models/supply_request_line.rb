class SupplyRequestLine < ApplicationRecord
  belongs_to :supply_request
  belongs_to :part

  validates :quantity, numericality: { greater_than: 0 }
  validate :part_must_belong_to_same_company

  private

  def part_must_belong_to_same_company
    return unless part && supply_request
    errors.add(:part, "debe pertenecer a tu empresa") if part.company_id != supply_request.company_id
  end
end
