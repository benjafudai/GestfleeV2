require 'rails_helper'

RSpec.describe 'Vehicle management', type: :request do
  let(:company) { create_company }

  context 'as admin' do
    before { sign_in admin_of(company) }

    it 'creates a vehicle in the admin company' do
      expect {
        post vehicles_path, params: { vehicle: { plate: 'NEW123', brand: 'Volvo', year: 2020 } }
      }.to change(Vehicle.unscoped, :count).by(1)

      vehicle = Vehicle.unscoped.find_by!(plate: 'NEW123')
      expect(vehicle.company).to eq(company)
      expect(vehicle).to be_active
      expect(response).to redirect_to(vehicle_path(vehicle))
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it 'shows the form again when the data is invalid' do
      expect {
        post vehicles_path, params: { vehicle: { plate: '', year: 1900 } }
      }.not_to change(Vehicle.unscoped, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'updates and deletes a vehicle' do
      vehicle = create_vehicle(company: company)

      patch vehicle_path(vehicle), params: { vehicle: { brand: 'Scania' } }
      expect(vehicle.reload.brand).to eq('Scania')

      expect { delete vehicle_path(vehicle) }.to change(Vehicle.unscoped, :count).by(-1)
      expect(response).to redirect_to(vehicles_path)
    end
  end

  it 'does not let a driver create vehicles' do
    sign_in create_user(role: :chofer, company: company)

    expect {
      post vehicles_path, params: { vehicle: { plate: 'CHO123' } }
    }.not_to change(Vehicle.unscoped, :count)
    expect(response).to redirect_to(root_path)
  end
end
