class VehicleAssignment < ApplicationRecord
  belongs_to :vehicle
  belongs_to :user

  has_paper_trail

  # Scopes
  scope :active,      -> { where(ended_on: nil) }
  scope :historical,  -> { where.not(ended_on: nil) }
  scope :chronological, -> { order(started_on: :desc) }

  # Validations
  validates :started_on, presence: true
  validate :user_must_be_chofer
  validate :vehicle_has_no_active_assignment, on: :create
  validate :chofer_has_no_active_assignment, on: :create
  validate :ended_on_after_started_on, if: -> { ended_on.present? }

  private

  def user_must_be_chofer
    return unless user
    errors.add(:user, "debe tener rol de chofer") unless user.chofer?
  end

  def vehicle_has_no_active_assignment
    return unless vehicle
    if vehicle.vehicle_assignments.active.exists?
      errors.add(:vehicle, "ya tiene un chofer asignado actualmente")
    end
  end

  def chofer_has_no_active_assignment
    return unless user
    if user.vehicle_assignments.active.exists?
      errors.add(:user, "ya está asignado a otro vehículo actualmente")
    end
  end

  def ended_on_after_started_on
    if ended_on <= started_on
      errors.add(:ended_on, "debe ser posterior a la fecha de inicio")
    end
  end
end
