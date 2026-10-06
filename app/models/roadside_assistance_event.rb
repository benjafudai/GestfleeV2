class RoadsideAssistanceEvent < ApplicationRecord
  belongs_to :company
  belongs_to :vehicle
  belongs_to :user

  has_many_attached :photos
  has_paper_trail

  enum :status, { solicitado: 0, en_camino: 1, resuelto: 2 }

  default_scope { where(company: Current.company) }
  before_validation :assign_company

  after_create :notify_admins

  validates :description, presence: true
  
  private

  def assign_company
    self.company ||= Current.company
  end

  def notify_admins
    # Create an in-app notification first
    admins = company.users.where(role: [:admin, :superadmin])
    admins.each do |admin|
      Notification.create!(
        user: admin,
        notifiable: self,
        title: "¡Emergencia Reportada!",
        message: "El vehículo #{vehicle.plate} (Chofer: #{user.email}) ha reportado un evento de auxilio en ruta."
      )
      
      # Send Push Notification via WebPush
      admin.push_subscriptions.each do |sub|
        begin
          Webpush.payload_send(
            message: "Emergencia en ruta: Vehículo #{vehicle.plate} requiere auxilio.",
            endpoint: sub.endpoint,
            p256dh: sub.p256dh,
            auth: sub.auth,
            vapid: {
              subject: "mailto:admin@#{company.name.downcase.gsub(' ', '')}.com",
              public_key: Rails.application.credentials.dig(:webpush, :public_key),
              private_key: Rails.application.credentials.dig(:webpush, :private_key)
            }
          )
        rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription => e
          sub.destroy
        rescue => e
          Rails.logger.error "Error sending webpush notification: #{e.message}"
        end
      end
    end
  end
end
