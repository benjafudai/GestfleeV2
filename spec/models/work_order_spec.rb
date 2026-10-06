require "rails_helper"

# Stock deduction on completion is covered in work_order_logic_spec.rb.
RSpec.describe WorkOrder, type: :model do
  let(:company) { create_company }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let(:part) do
    Part.create!(company: company, sku: "PST-001", name: "Pastillas de freno", unit_of_measure: "juego", stock: 1, cost: 30_000)
  end

  it "only accepts a mechanic from the same company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    outsider = create_user(:mecanico, company: other)

    work_order = WorkOrder.new(company: company, vehicle: vehicle, mechanic: outsider)

    expect(work_order).not_to be_valid
    expect(work_order.errors[:mechanic]).to include("debe pertenecer a la misma empresa")
  end

  it "can't be completed without enough stock for its parts" do
    work_order = WorkOrder.create!(company: company, vehicle: vehicle, status: :in_progress)
    work_order.work_order_part_usages.create!(part: part, quantity: 2)

    expect(work_order.update(status: :completed)).to be false
    expect(work_order.errors[:base]).to include(a_string_starting_with("Stock insuficiente de Pastillas de freno"))
    expect(part.reload.stock).to eq(1)
  end

  {completed: "completada", cancelled: "cancelada"}.each do |status, label|
    it "can't be changed once #{status}" do
      work_order = WorkOrder.create!(company: company, vehicle: vehicle, status: :in_progress)
      work_order.update!(status: status)

      expect(work_order.update(notes: "otro cambio")).to be false
      expect(work_order.errors[:base]).to include("no se puede modificar una orden de trabajo ya #{label}")
    end
  end
end
