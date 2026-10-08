require 'rails_helper'

RSpec.describe 'User management', type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }

  def user_params(**attrs)
    { email: "nuevo-#{SecureRandom.hex(3)}@test.cl", password: TenantHelpers::SPEC_PASSWORD,
      password_confirmation: TenantHelpers::SPEC_PASSWORD, role: 'chofer' }.merge(attrs)
  end

  context 'as admin' do
    before { sign_in admin }

    it 'creates a user in their own company, whatever company is sent' do
      other = create_other_company

      expect {
        post users_path, params: { user: user_params(company_id: other.id) }
      }.to change(User, :count).by(1)

      expect(User.last.company).to eq(company)
      expect(response).to redirect_to(users_path)
    end

    it 'cannot create admins or superadmins' do
      %w[admin superadmin].each do |role|
        expect {
          post users_path, params: { user: user_params(role: role) }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'shows the form again when the data is invalid' do
      expect {
        post users_path, params: { user: user_params(email: 'no-es-correo') }
      }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'filters the list by role' do
      driver = create_user(:chofer, company: company)
      mechanic = create_user(:mecanico, company: company)

      get users_path, params: { role: 'chofer' }

      expect(response.body).to include(driver.email)
      expect(response.body).not_to include(mechanic.email)
    end

    it 'does not list users from other companies' do
      outsider = create_user(:chofer, company: create_other_company)

      get users_path

      expect(response.body).not_to include(outsider.email)
    end

    it 'changes the role of a user' do
      driver = create_user(:chofer, company: company)

      patch user_path(driver), params: { user: { role: 'analista' } }

      expect(driver.reload).to be_analista
      expect(response).to redirect_to(user_path(driver))
    end

    it 'cannot promote a user to admin' do
      driver = create_user(:chofer, company: company)

      patch user_path(driver), params: { user: { role: 'admin' } }

      expect(driver.reload).to be_chofer
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'deletes a user of their company' do
      driver = create_user(:chofer, company: company)

      expect { delete user_path(driver) }.to change(User, :count).by(-1)
      expect(response).to redirect_to(users_path)
    end

    it 'cannot delete themselves' do
      expect { delete user_path(admin) }.not_to change(User, :count)
      expect(flash[:alert]).to eq('No puedes eliminarte a ti mismo.')
    end
  end

  context 'as superadmin' do
    let(:superadmin) { create_user(:superadmin) }

    before { sign_in superadmin }

    it 'creates an admin for a chosen company' do
      post users_path, params: { user: user_params(role: 'admin', company_id: company.id) }

      expect(User.last).to be_admin
      expect(User.last.company).to eq(company)
    end

    it 'creates superadmins without a company' do
      post users_path, params: { user: user_params(role: 'superadmin', company_id: company.id) }

      expect(User.last).to be_superadmin
      expect(User.last.company).to be_nil
    end

    it 'filters users by company name' do
      other = create_other_company(name: 'Transportes Sur')
      outsider = create_user(:chofer, company: other)
      insider = create_user(:chofer, company: company)

      get users_path, params: { company_name: 'sur' }

      expect(response.body).to include(outsider.email)
      expect(response.body).not_to include(insider.email)
    end

    it 'keeps at least one admin in each company' do
      patch user_path(admin), params: { user: { role: 'chofer' } }
      expect(admin.reload).to be_admin
      expect(response).to have_http_status(:unprocessable_content)

      expect { delete user_path(admin) }.not_to change(User, :count)
      expect(flash[:alert]).to include('único administrador')
    end

    it 'removes the company when a user becomes superadmin' do
      driver = create_user(:chofer, company: company)

      patch user_path(driver), params: { user: { role: 'superadmin' } }

      expect(driver.reload).to be_superadmin
      expect(driver.company).to be_nil
    end

    it 'can remove an admin when the company has another one' do
      second_admin = create_user(:admin, company: company)

      expect { delete user_path(second_admin) }.to change(User, :count).by(-1)
    end
  end
end
