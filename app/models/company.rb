class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :expenses, dependent: :destroy
  accepts_nested_attributes_for :users
  has_many :vehicles, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :fuel_fills, dependent: :destroy
  has_many :checklist_templates, dependent: :destroy
  has_many :work_orders, through: :vehicles
  has_many :maintenance_plans, dependent: :destroy
  has_many :supply_requests, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :name, presence: true
  validates :rut, presence: true

  # Store configuration: { has_mechanic: ..., fuel_anomaly_threshold: 20, require_fuel_ticket: false }
  store :configuration, accessors: [ :has_mechanic, :has_analyst, :fuel_anomaly_threshold, :require_fuel_ticket ], coder: JSON

  def anomaly_threshold
    (fuel_anomaly_threshold.presence || 20).to_i
  end

  def require_ticket?
    require_fuel_ticket == true || require_fuel_ticket == "true" || require_fuel_ticket == "1" || require_fuel_ticket == 1
  end

  def has_mechanic?
    has_mechanic == true || has_mechanic == "true" || has_mechanic == "1" || has_mechanic == 1
  end

  def has_analyst?
    has_analyst == true || has_analyst == "true" || has_analyst == "1" || has_analyst == 1
  end
end
