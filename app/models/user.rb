class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :company, optional: true
  validates :company, presence: true, unless: :superadmin?

  enum :role, {
    admin: 0,
    chofer: 1,
    mecanico: 2,
    analista: 3,
    superadmin: 4
  }
  
  validates :role, presence: true

  has_paper_trail
  has_many :vehicle_assignments, foreign_key: :user_id, dependent: :destroy
  has_one  :active_assignment, -> { VehicleAssignment.active }, class_name: 'VehicleAssignment', foreign_key: :user_id
  has_many :reported_incidents, class_name: 'Incident', foreign_key: 'reporter_id', dependent: :destroy
  has_many :checklist_submissions, dependent: :destroy
  has_many :user_documents, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :roadside_assistance_events, dependent: :destroy
  has_many :password_reset_requests, dependent: :destroy
  has_many :resolved_password_reset_requests, class_name: 'PasswordResetRequest', foreign_key: :admin_id, dependent: :nullify
  has_many :fuel_fills, dependent: :destroy
  has_many :supply_requests, dependent: :destroy
  has_many :work_orders, foreign_key: :mechanic_id, dependent: :nullify, inverse_of: :mechanic
end
