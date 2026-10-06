require "rails_helper"

RSpec.describe WorkOrderPartUsage, type: :model do
  let(:company) { create_company }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let(:work_order) { WorkOrder.create!(company: company, vehicle: vehicle) }

  def part_of(company)
    Part.create!(company: company, sku: "PST-001", name: "Pastillas", unit_of_measure: "juego", stock: 3, cost: 1000)
  end

  it "needs a quantity above zero" do
    usage = work_order.work_order_part_usages.build(part: part_of(company), quantity: 0)

    expect(usage).not_to be_valid
    expect(usage.errors[:quantity]).to be_present
  end

  it "only accepts parts from the work order's company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    usage = work_order.work_order_part_usages.build(part: part_of(other), quantity: 1)

    expect(usage).not_to be_valid
    expect(usage.errors[:part]).to include("debe pertenecer a tu empresa")
  end
end
