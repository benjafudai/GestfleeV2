require "rails_helper"

RSpec.describe SupplyRequestLine, type: :model do
  let(:company) { create_company }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let(:supply_request) { SupplyRequest.create!(vehicle: vehicle, user: company_admin(company)) }

  def part_of(company, sku: "FLT-001")
    Part.create!(company: company, sku: sku, name: "Filtro", unit_of_measure: "unidad", stock: 5, cost: 1000)
  end

  it "needs a quantity above zero" do
    line = supply_request.supply_request_lines.build(part: part_of(company), quantity: 0)

    expect(line).not_to be_valid
    expect(line.errors[:quantity]).to be_present
  end

  it "only accepts parts from the request's company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    line = supply_request.supply_request_lines.build(part: part_of(other), quantity: 1)

    expect(line).not_to be_valid
    expect(line.errors[:part]).to include("debe pertenecer a tu empresa")
  end

  it "is valid with a part from the same company" do
    line = supply_request.supply_request_lines.build(part: part_of(company), quantity: 1)

    expect(line).to be_valid
  end
end
