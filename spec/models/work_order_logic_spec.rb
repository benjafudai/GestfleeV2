require 'rails_helper'

RSpec.describe WorkOrder, type: :model do
  describe 'stock deduction on completion' do
    let(:company) { Company.create!(name: 'Test Co', rut: '11.111.111-1') }
    let(:vehicle) { Vehicle.create!(company: company, plate: 'XX1234') }
    let(:part) { Part.create!(company: company, sku: 'P1', name: 'Part 1', unit_of_measure: 'unit', stock: 10, cost_cents: 100) }
    let(:mechanic) { User.create!(company: company, email: 'mech@test.com', password: 'password', role: :mecanico) }

    it 'deducts stock when status changes to completed' do
      Current.company = company
      
      work_order = WorkOrder.create!(
        company: company,
        vehicle: vehicle,
        mechanic: mechanic,
        status: :in_progress
      )
      
      work_order.work_order_part_usages.create!(
        part: part,
        quantity: 2
      )

      expect {
        work_order.update!(status: :completed)
      }.to change { part.reload.stock }.by(-2)
      
      movement = StockMovement.last
      expect(movement.movement_type).to eq('out')
      expect(movement.quantity).to eq(-2)
      expect(movement.reference).to include("WorkOrder ##{work_order.id}")
    end
  end
end
