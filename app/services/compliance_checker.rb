class ComplianceChecker
  def self.call
    Rails.logger.info "Iniciando chequeo de cumplimiento de vencimientos..."
    new.check_all
    Rails.logger.info "Chequeo finalizado."
  end

  def check_all
    check_vehicle_documents
    check_user_documents
  end

  private

  def check_vehicle_documents
    VehicleDocument.find_each do |doc|
      company = doc.vehicle&.company
      update_status_and_notify(doc, company)
    end
  end

  def check_user_documents
    UserDocument.find_each do |doc|
      company = doc.user&.company
      update_status_and_notify(doc, company)
    end
  end

  def update_status_and_notify(doc, company)
    return unless doc.due_on

    if doc.due_on < Date.today
      if doc.status != 'expired'
        doc.update(status: 'expired')
        notify_admins(company, doc, "Documento Vencido", "El documento #{doc.doc_type} ha vencido el #{doc.due_on}.")
      end
    elsif doc.due_on <= 30.days.from_now.to_date
      if doc.status != 'expiring'
        doc.update(status: 'expiring')
        notify_admins(company, doc, "Documento por vencer", "El documento #{doc.doc_type} vencerá pronto (#{doc.due_on}).")
      end
    else
      if doc.status != 'ok'
        doc.update(status: 'ok')
      end
    end
  end

  def notify_admins(company, notifiable, title, message_prefix)
    return unless company

    admins = company.users.where(role: [:admin, :superadmin])
    subject_name = notifiable.is_a?(VehicleDocument) ? notifiable.vehicle.plate : notifiable.user.email
    
    admins.find_each do |admin|
      # Avoid duplicate notifications for the same day/status change
      # This is basic, could be improved.
      Notification.create!(
        user: admin,
        notifiable: notifiable,
        title: "#{title}: #{subject_name}",
        message: "#{message_prefix} - #{subject_name}"
      )
    end
  end
end
