class FuelFill < ApplicationRecord
  belongs_to :vehicle
  belongs_to :user
  belongs_to :company

  has_one_attached :ticket
  has_one :expense, as: :source, dependent: :destroy

  validates :liters, presence: true, numericality: { greater_than: 0 }
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :odometer, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validate :ticket_presence_if_required

  before_save :calculate_km_per_liter
  after_create :sync_expense
  after_commit :check_anomaly_and_notify, on: :create

  default_scope { where(company: Current.company) }
  before_validation :assign_company

  private

  def assign_company
    self.company ||= Current.company
  end

  def ticket_presence_if_required
    if company&.require_ticket? && !ticket.attached?
      errors.add(:ticket, "La fotografía de la boleta es obligatoria para registrar cargas.")
    end
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

  def notify_admins_of_anomaly(avg)
    admins = company.users.where(role: [:admin, :superadmin, :analista])
    admins.each do |admin|
      Notification.create!(
        user: admin,
        notifiable: self,
        title: "Alerta de Consumo: #{vehicle.plate}",
        message: "Posible anomalía registrada. El rendimiento detectado (#{km_per_liter.round(2)} km/l) es significativamente inferior al promedio histórico (#{avg.round(2)} km/l)."
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
      description: "Carga de combustible (#{liters}L) a los #{odometer} km. #{notes}"
    ).save!
  end
end
