require "rails_helper"

RSpec.describe PartFitment, type: :model do
  let(:company) { create_company }
  let(:part) { Part.create!(company: company, sku: "FLT-001", name: "Filtro", unit_of_measure: "unidad", stock: 5, cost: 1000) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }

  it "takes the company from the part" do
    expect(PartFitment.create!(part: part, vehicle: vehicle).company).to eq(company)
  end

  it "only links a part to a vehicle of the same company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    outside_vehicle = Vehicle.create!(company: other, plate: "CD5678")

    fitment = PartFitment.new(part: part, vehicle: outside_vehicle)

    expect(fitment).not_to be_valid
    expect(fitment.errors[:vehicle]).to include("debe pertenecer a la misma empresa que el repuesto")
  end

  it "doesn't link the same part to the same vehicle twice" do
    PartFitment.create!(part: part, vehicle: vehicle)

    expect(PartFitment.new(part: part, vehicle: vehicle)).not_to be_valid
  end
end
