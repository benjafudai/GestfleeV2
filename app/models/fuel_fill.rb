class FuelFill < ApplicationRecord
  include CompanyScoped
  include VehicleAssignable
  vehicle_assignable_actor :user
  before_validation :assign_company_from_vehicle

  belongs_to :vehicle
  belongs_to :user

  has_one_attached :ticket
  has_one :expense, as: :source, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :liters, presence: true, numericality: { greater_than: 0, allow_nil: true }
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :odometer, presence: true, numericality: { greater_than: 0, allow_nil: true }
  validates :date, presence: true
  validates :currency, inclusion: { in: %w[CLP USD] }
  validate :ticket_must_be_attached
  validate :ticket_must_be_image

  before_save :calculate_km_per_liter
  after_create :sync_expense
  after_commit :check_anomaly_and_notify, on: :create

  private

  # Superadmin (sin empresa) registra cargas en vehículos de cualquier empresa: la carga hereda la empresa del vehículo.
  def assign_company_from_vehicle
    self.company ||= vehicle&.company
  end

  def ticket_must_be_attached
    errors.add(:ticket, "es obligatoria: sube una foto de la boleta para registrar la carga") unless ticket.attached?
  end

  def ticket_must_be_image
    return unless ticket.attached?
    return if ticket.content_type.to_s.start_with?("image/")

    errors.add(:ticket, "debe ser una imagen (jpg, png, etc.)")
  end

  def calculate_km_per_liter
    previous_fill = FuelFill.where(vehicle: vehicle).where('odometer < ?', odometer).order(odometer: :desc).first
    if previous_fill && previous_fill.odometer < odometer
      distance = odometer - previous_fill.odometer
      self.km_per_liter = distance.to_f / liters.to_f
    else
      self.km_per_liter = nil
    end
  end

  def check_anomaly_and_notify
    return unless km_per_liter

    # Calculate average from previous fills
    previous_fills = FuelFill.where(vehicle: vehicle)
                             .where.not(id: id)
                             .where.not(km_per_liter: nil)
                             .order(odometer: :desc).limit(10)

    if previous_fills.any?
      avg = previous_fills.average(:km_per_liter).to_f
      threshold_percentage = company.anomaly_threshold.to_f / 100.0
      lower_limit = avg * (1.0 - threshold_percentage)

      if km_per_liter < lower_limit
        notify_admins_of_anomaly(avg)
      end
    end
  end

  def format_km_per_liter(value)
    ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2, separator: ",", delimiter: ".")
  end

  def notify_admins_of_anomaly(avg)
    admins = company.users.where(role: [:admin, :superadmin, :analista])
    admins.each do |admin|
      Notification.create!(
        user: admin,
        notifiable: self,
        title: "Alerta de consumo: #{vehicle.plate}",
        message: "Posible anomalía registrada. El rendimiento detectado (#{format_km_per_liter(km_per_liter)} km/l) es significativamente inferior al promedio histórico (#{format_km_per_liter(avg)} km/l)."
      )
    end
  end

  def sync_expense
    build_expense(
      company: company,
      vehicle: vehicle,
      category: :fuel,
      amount: cost,
      currency: currency,
      date: date,
      description: [
        "Carga de combustible (#{ActiveSupport::NumberHelper.number_to_rounded(liters, precision: 2, strip_insignificant_zeros: true, separator: ",", delimiter: ".")} L) " \
        "a los #{ActiveSupport::NumberHelper.number_to_delimited(odometer, delimiter: ".")} km.",
        notes.presence
      ].compact.join(" ")
    ).save!
  end
end
