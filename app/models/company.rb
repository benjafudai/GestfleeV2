class Company < ApplicationRecord
  has_paper_trail

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
  has_many :parts, dependent: :destroy
  has_many :deliveries, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :checklist_submissions, dependent: :destroy
  has_many :part_fitments, dependent: :destroy
  has_many :roadside_assistance_events, dependent: :destroy

  validates :name, presence: true
  validates :rut, presence: true, uniqueness: true
  validates :users, presence: { message: "debe incluir al menos un administrador" }, on: :create

  # Store configuration: { has_mechanic: ..., has_bodeguero: ..., fuel_anomaly_threshold: 20 }
  store :configuration, accessors: [ :has_mechanic, :has_analyst, :has_bodeguero, :fuel_anomaly_threshold,
                                     :weekly_summary_enabled, :weekly_summary_emails ], coder: JSON

  WEEKLY_SUMMARY_MAX_EXTRA_EMAILS = 10

  validate :weekly_summary_emails_are_valid

  def anomaly_threshold
    (fuel_anomaly_threshold.presence || 20).to_i
  end

  def has_mechanic?
    has_mechanic == true || has_mechanic == "true" || has_mechanic == "1" || has_mechanic == 1
  end

  def has_analyst?
    has_analyst == true || has_analyst == "true" || has_analyst == "1" || has_analyst == 1
  end

  def has_bodeguero?
    has_bodeguero == true || has_bodeguero == "true" || has_bodeguero == "1" || has_bodeguero == 1
  end

  # Resumen semanal en PDF: activo salvo que la empresa lo apague.
  def weekly_summary_enabled?
    weekly_summary_enabled.nil? || ActiveModel::Type::Boolean.new.cast(weekly_summary_enabled)
  end

  # Correos adicionales del resumen, escritos separados por coma, punto y coma o salto de línea.
  def weekly_summary_extra_emails
    weekly_summary_emails.to_s.split(/[\s,;]+/).map { |email| email.strip.downcase }.reject(&:blank?).uniq
  end

  # Administradores de la empresa más los correos adicionales.
  def weekly_summary_recipients
    (users.where(role: :admin).order(:email).pluck(:email).map(&:downcase) + weekly_summary_extra_emails).uniq
  end

  private

  def weekly_summary_emails_are_valid
    emails = weekly_summary_extra_emails
    invalid = emails.reject { |email| email.match?(URI::MailTo::EMAIL_REGEXP) }
    if invalid.any?
      errors.add(:weekly_summary_emails, "tiene correos no válidos: #{invalid.join(', ')}")
    elsif emails.size > WEEKLY_SUMMARY_MAX_EXTRA_EMAILS
      errors.add(:weekly_summary_emails, "admite hasta #{WEEKLY_SUMMARY_MAX_EXTRA_EMAILS} correos")
    end
  end
end
