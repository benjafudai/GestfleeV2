# Envía el resumen semanal de una empresa con el PDF adjunto.
class WeeklySummaryMailer < ApplicationMailer
  helper :currency

  def summary(company, recipients:, period_end: nil)
    @summary = period_end ? WeeklySummary.new(company, period: (period_end - 6)..period_end) : WeeklySummary.last_week(company)
    @data = @summary.to_h
    pdf = WeeklySummaryPdf.new(@summary)
    attachments[pdf.filename] = { mime_type: "application/pdf", content: pdf.render }

    mail to: recipients, subject: "Resumen semanal de #{company.name}: #{@summary.period_label.delete_prefix('Semana ')}"
  end
end
