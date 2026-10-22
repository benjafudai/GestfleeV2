require "rails_helper"

RSpec.describe WeeklySummaryMailer do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create_company }

  before { allow(CurrencyConverter).to receive(:usd_to_clp).and_return(900) }

  it "sends last week's summary with the PDF attached" do
    travel_to(Time.zone.local(2026, 10, 19, 8)) do
      mail = described_class.summary(company, recipients: ["admin@uno.cl", "gerencia@uno.cl"])

      expect(mail.to).to eq(["admin@uno.cl", "gerencia@uno.cl"])
      expect(mail.subject).to eq("Resumen semanal de Transportes Uno: del 12 al 18 de octubre de 2026")
      expect(mail.attachments.map(&:filename)).to eq(["resumen-semanal-transportes-uno-2026-10-18.pdf"])
      expect(mail.attachments.first.content_type).to start_with("application/pdf")
      expect(mail.text_part.decoded).to include("Documentos vencidos: 0")
    end
  end
end
