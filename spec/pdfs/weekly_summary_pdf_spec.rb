require "rails_helper"

RSpec.describe WeeklySummaryPdf do
  let(:company) { create_company(name: "Transportes Ñandú 🚚") }
  let(:summary) { WeeklySummary.last_week(company, today: Date.new(2026, 10, 19)) }

  before { allow(CurrencyConverter).to receive(:usd_to_clp).and_return(900) }

  it "renders a PDF even with characters the built-in font can't draw" do
    vehicle = create_vehicle(company: company, plate: "AB1234")
    VehicleDocument.create!(vehicle: vehicle, doc_type: :seguro, due_on: Date.new(2026, 10, 10), file: pdf_file)
    Expense.create!(company: company, category: :tolls, amount: 10_000, date: Date.new(2026, 10, 13))

    output = described_class.new(summary).render

    expect(output).to start_with("%PDF")
  end

  it "spreads long lists over more pages" do
    vehicles = Array.new(15) { |i| create_vehicle(company: company, plate: "PL#{i.to_s.rjust(4, '0')}") }
    vehicles.each { |vehicle| VehicleDocument.create!(vehicle: vehicle, doc_type: :seguro, due_on: Date.new(2026, 10, 1), file: pdf_file) }
    vehicles.each { |vehicle| WorkOrder.create!(company: company, vehicle: vehicle, status: :pending, notes: "Revisar frenos " * 5) }

    output = described_class.new(summary).render

    expect(output.scan(%r{/Type /Page\b}).size).to be >= 2
  end

  it "names the file after the company and the week's last day" do
    expect(described_class.new(summary).filename).to eq("resumen-semanal-transportes-nandu-2026-10-18.pdf")
  end
end
