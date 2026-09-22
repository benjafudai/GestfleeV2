class PartFitment < ApplicationRecord
  belongs_to :part
  belongs_to :vehicle

  validates :vehicle_id, uniqueness: { scope: :part_id }
end
