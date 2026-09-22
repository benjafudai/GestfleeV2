class PartFitment < ApplicationRecord
  include CompanyScoped

  belongs_to :part
  belongs_to :vehicle

  validates :vehicle_id, uniqueness: { scope: :part_id }
  validate :part_and_vehicle_must_match_company

  private

  # La empresa se toma del repuesto, con Current.company solo como respaldo.
  def assign_company
    self.company ||= part&.company || Current.company
  end

  def part_and_vehicle_must_match_company
    return unless part && vehicle
    errors.add(:vehicle, "debe pertenecer a la misma empresa que el repuesto") if part.company_id != vehicle.company_id
  end
end
