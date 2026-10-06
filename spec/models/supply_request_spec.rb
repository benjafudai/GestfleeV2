require "rails_helper"

RSpec.describe SupplyRequest, type: :model do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let(:part) do
    Part.create!(company: company, sku: "FLT-001", name: "Filtro de aceite", unit_of_measure: "unidad", stock: 5, cost: 12_000)
  end

  def request_for(quantity)
    SupplyRequest.create!(vehicle: vehicle, user: admin, status: :requested,
                          supply_request_lines_attributes: [{ part_id: part.id, quantity: quantity }])
  end

  it "takes the company from the vehicle" do
    expect(request_for(1).company).to eq(company)
  end

  describe "delivering it" do
    it "takes the parts out of stock and records the movement" do
      supply_request = request_for(2)

      expect { supply_request.update!(status: :delivered) }.to change { part.reload.stock }.from(5).to(3)

      movement = StockMovement.last
      expect(movement).to have_attributes(part: part, quantity: -2, movement_type: "out",
                                          reference: "SupplyRequest ##{supply_request.id}")
    end

    it "is refused when there isn't enough stock" do
      supply_request = request_for(8)

      expect(supply_request.update(status: :delivered)).to be false
      expect(supply_request.errors[:base]).to include(a_string_starting_with("Stock insuficiente de Filtro de aceite"))
      expect(part.reload.stock).to eq(5)
    end
  end

  it "can't be changed once delivered" do
    supply_request = request_for(1)
    supply_request.update!(status: :delivered)

    expect(supply_request.update(status: :requested)).to be false
    expect(supply_request.errors[:base]).to include("no se puede modificar una solicitud ya entregada")
  end

  it "doesn't take stock when it moves to a status other than delivered" do
    supply_request = request_for(2)

    expect { supply_request.update!(status: :purchasing) }.not_to change { part.reload.stock }
  end
end
