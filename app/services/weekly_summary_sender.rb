# Envía el resumen de la semana pasada a cada empresa que lo tiene activo.
# Lo corre la tarea programada del servidor: bin/rails resumen:semanal (lunes en la mañana).
class WeeklySummarySender
  Result = Struct.new(:sent, :skipped, :failed, keyword_init: true)

  # En producción el correo sale solo si el servidor tiene SMTP configurado.
  def self.mail_configured?
    !Rails.env.production? || ENV["SMTP_ADDRESS"].present?
  end

  def self.call(today: Date.current, logger: Rails.logger)
    new(today: today, logger: logger).call
  end

  def initialize(today:, logger:)
    @week_end = today.beginning_of_week - 1
    @logger = logger
  end

  def call
    result = Result.new(sent: [], skipped: [], failed: [])
    Company.order(:name).find_each do |company|
      recipients = company.weekly_summary_recipients
      if !company.weekly_summary_enabled? || recipients.empty?
        result.skipped << company.name
        next
      end

      WeeklySummaryMailer.summary(company, recipients: recipients, period_end: @week_end).deliver_now
      result.sent << company.name
    rescue StandardError => e
      # Una empresa con problemas no detiene el envío a las demás.
      result.failed << company.name
      @logger.error "Resumen semanal de #{company.name} (id #{company.id}) no se envió: #{e.class}: #{e.message}"
    end
    result
  end
end
