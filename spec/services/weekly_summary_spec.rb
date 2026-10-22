require "rails_helper"

RSpec.describe WeeklySummary do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { create_vehicle(company: company, plate: "AB1234") }
  # Lunes 19 de octubre de 2026: la semana pasada es del 12 al 18.
  let(:monday) { Date.new(2026, 10, 19) }
  let(:summary) { described_class.last_week(company, today: monday) }

  before { allow(CurrencyConverter).to receive(:usd_to_clp).and_return(900) }

  it "covers last week, Monday to Sunday" do
    expect(summary.period).to eq(Date.new(2026, 10, 12)..Date.new(2026, 10, 18))
    expect(summary.period_label).to eq("Semana del 12 al 18 de octubre de 2026")
  end

  it "names both months when the week crosses them" do
    crossing = described_class.last_week(company, today: Date.new(2026, 10, 5))

    expect(crossing.period_label).to eq("Semana del 28 de septiembre al 4 de octubre de 2026")
  end

  it "adds up the week's expenses in pesos, by category" do
    Expense.create!(company: company, category: :tolls, amount: 10_000, date: Date.new(2026, 10, 13))
    Expense.create!(company: company, category: :tolls, amount: 10, currency: "USD", date: Date.new(2026, 10, 18))
    Expense.create!(company: company, category: :parts, amount: 99_000, date: Date.new(2026, 10, 19)) # semana siguiente

    expenses = summary.to_h[:expenses]

    expect(expenses[:by_category]).to eq("tolls" => 19_000.0)
    expect(expenses[:total_clp]).to eq(19_000.0)
  end

  it "lists expired documents and the ones due within 30 days of the week's end" do
    VehicleDocument.create!(vehicle: vehicle, doc_type: :seguro, due_on: Date.new(2026, 10, 10), file: pdf_file)
    VehicleDocument.create!(vehicle: vehicle, doc_type: :revision_tecnica, due_on: Date.new(2026, 11, 10), file: pdf_file)
    VehicleDocument.create!(vehicle: vehicle, doc_type: :padron, due_on: Date.new(2027, 1, 10), file: pdf_file)

    documents = summary.to_h[:documents]

    expect(documents).to include(expired: 1, expiring: 1)
    expect(documents[:rows].map { |row| row[:type] }).to eq(["Seguro", "Revisión técnica"])
  end

  it "counts open work orders and the ones completed during the week" do
    travel_to(Time.zone.local(2026, 10, 14, 10)) do
      WorkOrder.create!(company: company, vehicle: vehicle, status: :pending)
      WorkOrder.create!(company: company, vehicle: vehicle, status: :completed)
    end

    orders = summary.to_h[:work_orders]

    expect(orders).to include(created: 2, completed: 1, open_count: 1)
    expect(orders[:open].first).to include(plate: "AB1234", status: "Pendiente")
  end

  it "only looks at its own company" do
    other = create_other_company
    Expense.create!(company: other, category: :tolls, amount: 50_000, date: Date.new(2026, 10, 13))
    create_part(company: other, stock: 1)

    data = summary.to_h

    expect(data[:expenses][:total_clp]).to eq(0)
    expect(data[:low_stock_parts]).to be_empty
  end

  it "lists the products under their minimum" do
    Product.create!(company: company, name: "Posta negra", unit: "kg", stock: 10, min_stock: 40)
    Product.create!(company: company, name: "Lomo vetado", unit: "kg", stock: 100, min_stock: 40)

    expect(summary.to_h[:low_stock_products]).to eq([{ name: "Posta negra", code: nil, stock: 10.0, min_stock: 40.0, unit: "kg" }])
  end

  it "counts the week's deliveries and adds up what was delivered" do
    driver = create_user(:chofer, company: company)
    lomo = Product.create!(company: company, name: "Lomo vetado", unit: "kg", stock: 100)
    deliver = lambda do |at, quantity|
      travel_to(at) do
        Delivery.new(company: company, driver: driver, customer: "Cliente", recipient_name: "Juan", photo: png_file,
                     lines_attributes: [{ product_id: lomo.id, quantity: quantity }]).tap { |d| d.register(by: driver) }
      end
    end
    deliver.call(Time.zone.local(2026, 10, 13, 10), 10)
    deliver.call(Time.zone.local(2026, 10, 15, 10), 5)
    deliver.call(Time.zone.local(2026, 10, 16, 10), 7).cancel(by: driver)
    deliver.call(Time.zone.local(2026, 10, 19, 10), 20) # semana siguiente

    expect(summary.to_h[:deliveries]).to eq(delivered: 2, cancelled: 1, by_product: [{ name: "Lomo vetado", unit: "kg", quantity: 15.0 }])
  end

  it "lists parts with low stock" do
    create_part(company: company, name: "Filtro de aire", stock: 2)
    create_part(company: company, name: "Aceite", stock: 40)

    expect(summary.to_h[:low_stock_parts].map { |part| part[:name] }).to eq(["Filtro de aire"])
  end
end
