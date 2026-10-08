class Vehicle < ApplicationRecord
  include CompanyScoped

  has_paper_trail

  has_many :vehicle_documents, dependent: :destroy
  has_many :vehicle_assignments, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :fuel_fills, dependent: :destroy
  has_one  :active_assignment, -> { active }, class_name: 'VehicleAssignment'
  has_many :checklist_submissions, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :roadside_assistance_events, dependent: :destroy
  has_many :fuel_fills, dependent: :destroy
  has_many :work_orders, dependent: :destroy
  has_many :supply_requests, dependent: :destroy
  has_many :part_fitments, dependent: :destroy
  belongs_to :vehicle_model, optional: true

  enum :status, { active: 0, maintenance: 1, inactive: 2 }

  validates :plate, presence: true, uniqueness: true
  validates :year, numericality: { allow_nil: true, greater_than: 1950 }
  validates :hour_meter, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :fill_from_vehicle_model

  private

  # Al elegir un modelo de la biblioteca, completa marca y modelo si vienen vacíos.
  def fill_from_vehicle_model
    return unless vehicle_model

    self.brand = vehicle_model.brand if brand.blank?
    self.model = vehicle_model.model if model.blank?
  end
end
