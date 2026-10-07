require 'rails_helper'

RSpec.describe 'Parts inventory', type: :request do
  let(:company) { with_modules(create_company, has_mechanic: true) }

  context 'as admin' do
    before { sign_in company_admin(company) }

    it 'creates a part linked to vehicles' do
      vehicle = create_vehicle(company: company)

      expect {
        post parts_path, params: { part: { sku: 'FIL-01', name: 'Filtro aceite', unit_of_measure: 'unidad',
                                           stock: 4, cost: 8_000, currency: 'CLP', vehicle_ids: [ vehicle.id ] } }
      }.to change(Part.unscoped, :count).by(1)

      part = Part.unscoped.last
      expect(part.company).to eq(company)
      expect(part.vehicles).to eq([ vehicle ])
    end

    it 'rejects a repeated SKU in the same company' do
      create_part(company: company, sku: 'FIL-01')

      post parts_path, params: { part: { sku: 'FIL-01', name: 'Otro', unit_of_measure: 'unidad' } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'updates and deletes a part' do
      part = create_part(company: company)

      patch part_path(part), params: { part: { stock: 12 } }
      expect(part.reload.stock).to eq(12)

      patch part_path(part), params: { part: { stock: -1 } }
      expect(response).to have_http_status(:unprocessable_content)

      expect { delete part_path(part) }.to change(Part.unscoped, :count).by(-1)
    end
  end

  it 'does not let a mechanic edit stock' do
    part = create_part(company: company, stock: 3)
    sign_in create_user(:mecanico, company: company)

    patch part_path(part), params: { part: { stock: 100 } }

    expect(part.reload.stock).to eq(3)
    expect(response).to redirect_to(root_path)
  end
end
