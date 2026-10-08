require 'rails_helper'

RSpec.describe 'Company management', type: :request do
  before { sign_in create_user(:superadmin) }

  it 'creates a company together with its admin' do
    expect {
      post companies_path, params: {
        company: { name: 'Fletes Norte', rut: '76.123.456-7',
                   users_attributes: { '0' => { email: 'jefe@norte.cl', password: TenantHelpers::SPEC_PASSWORD,
                                                password_confirmation: TenantHelpers::SPEC_PASSWORD, role: 'chofer' } } }
      }
    }.to change(Company, :count).by(1).and change(User, :count).by(1)

    company = Company.find_by!(rut: '76.123.456-7')
    expect(company.users.sole).to be_admin # el rol enviado se ignora
    expect(response).to redirect_to(companies_path)
  end

  it 'refuses a company without an admin' do
    expect {
      post companies_path, params: { company: { name: 'Sin admin', rut: '1-9' } }
    }.not_to change(Company, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'searches by name or RUT' do
    create_other_company(name: 'Transportes Andes')
    create_other_company(name: 'Buses Costa')

    get companies_path, params: { query: 'andes' }

    expect(response.body).to include('Transportes Andes')
    expect(response.body).not_to include('Buses Costa')
  end

  it 'removes mechanics when the mechanic module is turned off' do
    company = with_modules(create_company, has_mechanic: true)
    create_user(:mecanico, company: company)

    patch company_path(company), params: { company: { has_mechanic: '0' } }

    expect(company.reload).not_to be_has_mechanic
    expect(company.users.mecanico).to be_empty
    expect(flash[:notice]).to include('Se eliminaron 1 mecánicos')
  end

  it 'removes analysts when the analyst module is turned off' do
    company = with_modules(create_company, has_analyst: true)
    create_user(:analista, company: company)

    patch company_path(company), params: { company: { has_analyst: '0' } }

    expect(company.users.analista).to be_empty
  end

  it 'does not create users when updating the configuration' do
    company = create_other_company

    expect {
      patch company_path(company), params: {
        company: { name: 'Nuevo nombre', users_attributes: { '0' => { email: 'x@x.cl', password: TenantHelpers::SPEC_PASSWORD } } }
      }
    }.not_to change(User, :count)
    expect(company.reload.name).to eq('Nuevo nombre')
  end

  it 'shows the form again when the update is invalid' do
    company = create_other_company

    patch company_path(company), params: { company: { name: '' } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'deletes a company with its data' do
    company = create_other_company
    create_vehicle(company: company)

    expect { delete company_path(company) }.to change(Company, :count).by(-1)
    expect(Vehicle.unscoped.where(company: company)).to be_empty
  end
end
