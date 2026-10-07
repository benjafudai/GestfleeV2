require 'rails_helper'

RSpec.describe WorkOrder, type: :model do
  let(:company) { create_company }
  let(:vehicle) { create_vehicle(company: company) }
  let(:part) { create_part(company: company, stock: 10) }
  let(:mechanic) { create_user(role: :mecanico, company: company) }
  let(:work_order) { WorkOrder.create!(company: company, vehicle: vehicle, mechanic: mechanic, status: :in_progress) }

  describe 'stock deduction on completion' do
    it 'deducts stock and records an outgoing movement' do
      work_order.work_order_part_usages.create!(part: part, quantity: 2)

      expect {
        work_order.update!(status: :completed)
      }.to change { part.reload.stock }.by(-2)

      movement = StockMovement.last
      expect(movement.movement_type).to eq('out')
      expect(movement.quantity).to eq(-2)
      expect(movement.reference).to eq("WorkOrder ##{work_order.id}")
    end

    it 'does not touch stock while the order is still in progress' do
      work_order.work_order_part_usages.create!(part: part, quantity: 2)

      expect { work_order.update!(notes: "Cambio de filtro") }.not_to change { part.reload.stock }
      expect(StockMovement.count).to eq(0)
    end

    it 'refuses to complete when there is not enough stock' do
      work_order.work_order_part_usages.create!(part: part, quantity: 11)

      expect(work_order.update(status: :completed)).to be(false)
      expect(work_order.errors[:base].join).to include("Stock insuficiente de #{part.name}")
      expect(part.reload.stock).to eq(10)
      expect(StockMovement.count).to eq(0)
    end
  end

  describe 'validations' do
    it 'cannot be modified once completed' do
      work_order.update!(status: :completed)

      expect(work_order.update(notes: "otra cosa")).to be(false)
      expect(work_order.errors[:base].join).to include("ya completada")
    end

    it 'cannot be modified once cancelled' do
      work_order.update!(status: :cancelled)

      expect(work_order.update(status: :in_progress)).to be(false)
      expect(work_order.errors[:base].join).to include("ya cancelada")
    end

    it 'rejects a mechanic from another company' do
      outsider = create_user(role: :mecanico, company: create_company)
      order = WorkOrder.new(company: company, vehicle: vehicle, mechanic: outsider)

      expect(order).not_to be_valid
      expect(order.errors[:mechanic]).to include("debe pertenecer a la misma empresa")
    end

    it 'rejects parts from another company' do
      foreign_part = create_part(company: create_company, stock: 5)
      usage = work_order.work_order_part_usages.build(part: foreign_part, quantity: 1)

      expect(usage).not_to be_valid
      expect(usage.errors[:part]).to include("debe pertenecer a tu empresa")
    end
  end
end
