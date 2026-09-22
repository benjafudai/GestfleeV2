class Incident < ApplicationRecord
  belongs_to :vehicle
  belongs_to :reporter, class_name: 'User'
  belongs_to :company

  has_many_attached :photos
  has_paper_trail

  enum status: { pending: 0, in_review: 1, resolved: 2 }
  enum severity: { low: 0, medium: 1, high: 2, critical: 3 }

  after_initialize :set_defaults, if: :new_record?

  validates :description, presence: true

  private

  def set_defaults
    self.status ||= :pending
    self.severity ||= :low
  end
  validate :reporter_must_be_assigned_to_vehicle, on: :create

  private

  def reporter_must_be_assigned_to_vehicle
    return unless reporter && vehicle
    if reporter.chofer? && reporter.active_assignment&.vehicle_id != vehicle_id
      errors.add(:vehicle, "debe ser el que tienes asignado actualmente")
    end
  end
end
