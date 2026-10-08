require 'rails_helper'

RSpec.describe 'Supply request management', type: :request do
  let(:company) { with_modules(create_company, has_mechanic: true) }
  let(:vehicle) { create_vehicle(company: company) }
  let(:mechanic) { create_user(:mecanico, company: company) }
  let(:part) { create_part(company: company, stock: 5) }

  def create_request(user: mechanic, quantity: 2)
    SupplyRequest.create!(vehicle: vehicle, user: user,
                          supply_request_lines_attributes: [ { part_id: part.id, quantity: quantity } ])
  end

  context 'as mechanic' do
    before { sign_in mechanic }

    it 'asks for parts for a vehicle' do
      expect {
        post supply_requests_path, params: {
          supply_request: { vehicle_id: vehicle.id, status: 'delivered',
                            supply_request_lines_attributes: { '0' => { part_id: part.id, quantity: 2 } } }
        }
      }.to change(SupplyRequest.unscoped, :count).by(1)

      supply_request = SupplyRequest.unscoped.last
      expect(supply_request.user).to eq(mechanic)
      expect(supply_request).to be_requested # el estado enviado se ignora
      expect(part.reload.stock).to eq(5)
    end

    it 'shows the form again when a line is invalid' do
      expect {
        post supply_requests_path, params: {
          supply_request: { vehicle_id: vehicle.id,
                            supply_request_lines_attributes: { '0' => { part_id: part.id, quantity: 0 } } }
        }
      }.not_to change(SupplyRequest.unscoped, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'only sees their own requests' do
      own = create_request
      other = create_request(user: create_user(:mecanico, company: company))

      get supply_requests_path

      expect(response.body).to include(supply_request_path(own))
      expect(response.body).not_to include(supply_request_path(other))
    end

    it 'cannot change the status' do
      supply_request = create_request

      patch change_status_supply_request_path(supply_request), params: { status: 'delivered' }

      expect(supply_request.reload).to be_requested
      expect(response).to redirect_to(root_path)
    end
  end

  context 'as admin' do
    before { sign_in company_admin(company) }

    it 'delivers a request and discounts stock' do
      supply_request = create_request

      patch change_status_supply_request_path(supply_request), params: { status: 'delivered' }

      expect(supply_request.reload).to be_delivered
      expect(part.reload.stock).to eq(3)
      expect(flash[:notice]).to eq('Estado de la solicitud actualizado.')
    end

    it 'explains why a request cannot be delivered' do
      supply_request = create_request(quantity: 9)

      patch change_status_supply_request_path(supply_request), params: { status: 'delivered' }

      expect(supply_request.reload).to be_requested
      expect(flash[:alert]).to include('Stock insuficiente')
    end

    it 'rejects an unknown status' do
      supply_request = create_request

      patch change_status_supply_request_path(supply_request), params: { status: 'perdido' }

      expect(flash[:alert]).to eq('Estado no válido.')
    end

    it 'edits the admin notes and deletes the request' do
      supply_request = create_request

      patch supply_request_path(supply_request), params: { supply_request: { admin_notes: 'Pedido a proveedor' } }
      expect(supply_request.reload.admin_notes).to eq('Pedido a proveedor')

      expect { delete supply_request_path(supply_request) }.to change(SupplyRequest.unscoped, :count).by(-1)
      expect(response).to redirect_to(supply_requests_url)
    end
  end
end
