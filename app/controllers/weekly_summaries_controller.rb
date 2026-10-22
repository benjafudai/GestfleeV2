class WeeklySummariesController < ApplicationController
  # Errores de conexión con el servidor de correo al enviar la prueba.
  MAIL_ERRORS = [Net::SMTPError, IOError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError].freeze

  before_action :authenticate_user!
  before_action :set_company

  def show
    authorize :weekly_summary, :show?
    @summary = WeeklySummary.last_week(@company)

    respond_to do |format|
      format.html
      format.pdf do
        pdf = WeeklySummaryPdf.new(@summary)
        send_data pdf.render, filename: pdf.filename, type: "application/pdf", disposition: "attachment"
      end
    end
  end

  def update
    authorize :weekly_summary, :update?
    if @company.update(summary_params)
      redirect_to weekly_summary_path, notice: "Configuración del resumen semanal guardada."
    else
      @summary = WeeklySummary.last_week(@company)
      render :show, status: :unprocessable_entity
    end
  end

  # Envía el resumen de la semana pasada solo a quien lo pide, para probar el correo.
  def deliver
    authorize :weekly_summary, :deliver?
    unless WeeklySummarySender.mail_configured?
      return redirect_to weekly_summary_path,
                         alert: "El correo todavía no está configurado en el servidor. Mientras tanto puedes descargar el PDF."
    end

    WeeklySummaryMailer.summary(@company, recipients: [current_user.email]).deliver_now
    redirect_to weekly_summary_path, notice: "Te enviamos el resumen a #{current_user.email}."
  rescue *MAIL_ERRORS => e
    Rails.logger.error "Resumen semanal de prueba no se envió: #{e.class}: #{e.message}"
    redirect_to weekly_summary_path, alert: "No se pudo enviar el correo. Revisa la configuración del correo en el servidor."
  end

  private

  def set_company
    @company = current_user.company
  end

  def summary_params
    params.require(:company).permit(:weekly_summary_enabled, :weekly_summary_emails)
  end
end
