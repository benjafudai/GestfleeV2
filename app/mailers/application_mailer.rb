class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "GestFlee <no-responder@gestflee.cl>")
  layout "mailer"
end
