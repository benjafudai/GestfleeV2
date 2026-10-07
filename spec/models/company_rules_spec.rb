require 'rails_helper'

RSpec.describe Company, type: :model do
  it 'requires at least one administrator when created' do
    company = Company.new(name: 'Sin admin', rut: '1.111.111-1')

    expect(company).not_to be_valid
    expect(company.errors[:users]).to include('debe incluir al menos un administrador')
  end

  it 'requires a unique RUT' do
    existing = create_company
    duplicate = Company.new(name: 'Copia', rut: existing.rut,
                            users_attributes: [ { email: 'otro@test.cl', password: TestData::PASSWORD, role: :admin } ])

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:rut]).to be_present
  end

  describe 'configuration flags' do
    it 'reads has_mechanic from the values a form can send' do
      company = create_company
      [ true, 'true', '1', 1 ].each do |value|
        company.has_mechanic = value
        expect(company.has_mechanic?).to be(true), "expected #{value.inspect} to enable mechanics"
      end
      [ false, 'false', '0', nil ].each do |value|
        company.has_mechanic = value
        expect(company.has_mechanic?).to be(false), "expected #{value.inspect} to disable mechanics"
      end
    end

    it 'defaults the fuel anomaly threshold to 20%' do
      company = create_company
      expect(company.anomaly_threshold).to eq(20)

      company.fuel_anomaly_threshold = '35'
      expect(company.anomaly_threshold).to eq(35)
    end
  end
end

RSpec.describe User, type: :model do
  it 'requires a company for every role except superadmin' do
    expect(User.new(email: 'a@test.cl', password: TestData::PASSWORD, role: :chofer)).not_to be_valid
    expect(User.new(email: 'b@test.cl', password: TestData::PASSWORD, role: :superadmin)).to be_valid
  end
end
