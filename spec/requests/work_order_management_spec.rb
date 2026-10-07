require 'rails_helper'

RSpec.describe 'Work order management', type: :request do
  let(:company) { with_modules(create_company, has_mechanic: true) }
  let(:vehicle) { create_vehicle(company: company) }
  let(:mechanic) { create_user(:mecanico, company: company) }
  let(:part) { create_part(company: company, stock: 10) }

  def create_order(**attrs)
    WorkOrder.create!(company: company, vehicle: vehicle, mechanic: mechanic, status: :in_progress, **attrs)
  end

  context 'as mechanic' do
    before { sign_in mechanic }

    it 'creates an order with tasks and parts' do
      expect {
        post work_orders_path, params: {
          work_order: { vehicle_id: vehicle.id, mechanic_id: mechanic.id, status: 'pending', notes: 'Frenos',
                        work_order_tasks_attributes: { '0' => { description: 'Cambiar pastillas' } },
                        work_order_part_usages_attributes: { '0' => { part_id: part.id, quantity: 2 } } }
        }
      }.to change(WorkOrder.unscoped, :count).by(1)

      order = WorkOrder.unscoped.last
      expect(order.company).to eq(company)
      expect(order.work_order_tasks.map(&:description)).to eq([ 'Cambiar pastillas' ])
      expect(order.work_order_part_usages.sole.quantity).to eq(2)
      expect(response).to redirect_to(work_order_path(order))
    end

    it 'shows the form again when the data is invalid' do
      expect {
        post work_orders_path, params: { work_order: { vehicle_id: '', notes: 'x' } }
      }.not_to change(WorkOrder.unscoped, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'completes an order and discounts the parts used' do
      order = create_order
      order.work_order_part_usages.create!(part: part, quantity: 3)

      patch change_status_work_order_path(order), params: { status: 'completed' }

      expect(order.reload).to be_completed
      expect(part.reload.stock).to eq(7)
      expect(flash[:notice]).to eq('Estado actualizado exitosamente.')
    end

    it 'explains why an order cannot be completed' do
      order = create_order
      order.work_order_part_usages.create!(part: part, quantity: 30)

      patch change_status_work_order_path(order), params: { status: 'completed' }

      expect(order.reload).to be_in_progress
      expect(flash[:alert]).to include('Stock insuficiente')
    end

    it 'rejects an unknown status' do
      order = create_order

      patch change_status_work_order_path(order), params: { status: 'volando' }

      expect(order.reload).to be_in_progress
      expect(flash[:alert]).to eq('Estado inválido.')
    end

    it 'updates the notes of an order' do
      order = create_order

      patch work_order_path(order), params: { work_order: { notes: 'Revisar luces' } }

      expect(order.reload.notes).to eq('Revisar luces')
    end

    it 'cannot delete orders' do
      order = create_order

      expect { delete work_order_path(order) }.not_to change(WorkOrder.unscoped, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  it 'lets an admin delete an order' do
    order = create_order
    sign_in company_admin(company)

    expect { delete work_order_path(order) }.to change(WorkOrder.unscoped, :count).by(-1)
    expect(response).to redirect_to(work_orders_path)
  end
end
