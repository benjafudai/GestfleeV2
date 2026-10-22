namespace :resumen do
  desc "Envía por correo el resumen semanal (PDF) de la semana pasada a cada empresa"
  task semanal: :environment do
    abort "No se envió nada: falta configurar el correo (SMTP_ADDRESS y sus datos)." unless WeeklySummarySender.mail_configured?

    result = WeeklySummarySender.call
    puts "Resumen semanal: #{result.sent.size} enviados, #{result.skipped.size} sin envío (apagado o sin destinatarios), " \
         "#{result.failed.size} con error."
    abort "Fallaron: #{result.failed.join(', ')}. Revisa el log." if result.failed.any?
  end
end
