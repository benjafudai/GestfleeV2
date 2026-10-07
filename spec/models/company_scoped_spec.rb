require 'rails_helper'

# CompanyScoped es la base del multi-tenant: cada consulta queda limitada a la
# empresa del usuario conectado (Current.company).
RSpec.describe CompanyScoped, type: :model do
  let(:company_a) { create_company }
  let(:company_b) { create_company }
  let!(:vehicle_a) { create_vehicle(company: company_a) }
  let!(:vehicle_b) { create_vehicle(company: company_b) }

  it 'only returns records of the current company' do
    Current.company = company_a

    expect(Vehicle.all).to contain_exactly(vehicle_a)
    expect { Vehicle.find(vehicle_b.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'returns every company when there is no current company (superadmin)' do
    Current.company = nil

    expect(Vehicle.all).to include(vehicle_a, vehicle_b)
  end

  it 'assigns the current company to new records' do
    Current.company = company_b

    vehicle = Vehicle.create!(plate: 'ZZ9999')
    expect(vehicle.company).to eq(company_b)
  end
end
