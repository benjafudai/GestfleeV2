require 'rails_helper'

RSpec.describe 'Maintenance plan management', type: :request do
  let(:company) { with_modules(create_company, has_mechanic: true) }

  context 'as admin' do
    before { sign_in company_admin(company) }

    it 'creates a plan with its tasks, skipping blank ones' do
      expect {
        post maintenance_plans_path, params: {
          maintenance_plan: { name: 'Servicio 10.000 km', interval_km: 10_000,
                              maintenance_task_templates_attributes: {
                                '0' => { description: 'Cambiar aceite', expected_duration_minutes: 30 },
                                '1' => { description: '', expected_duration_minutes: '' }
                              } }
        }
      }.to change(MaintenancePlan.unscoped, :count).by(1)

      plan = MaintenancePlan.unscoped.last
      expect(plan.company).to eq(company)
      expect(plan.maintenance_task_templates.map(&:description)).to eq([ 'Cambiar aceite' ])
      expect(response).to redirect_to(maintenance_plan_path(plan))
    end

    it 'requires a name' do
      expect {
        post maintenance_plans_path, params: { maintenance_plan: { name: '' } }
      }.not_to change(MaintenancePlan.unscoped, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'updates and deletes a plan' do
      plan = MaintenancePlan.create!(company: company, name: 'Plan A')

      patch maintenance_plan_path(plan), params: { maintenance_plan: { interval_days: 90 } }
      expect(plan.reload.interval_days).to eq(90)

      expect { delete maintenance_plan_path(plan) }.to change(MaintenancePlan.unscoped, :count).by(-1)
      expect(response).to redirect_to(maintenance_plans_path)
    end
  end

  it 'does not let a mechanic change plans' do
    plan = MaintenancePlan.create!(company: company, name: 'Plan A')
    sign_in create_user(:mecanico, company: company)

    patch maintenance_plan_path(plan), params: { maintenance_plan: { name: 'Otro' } }

    expect(plan.reload.name).to eq('Plan A')
    expect(response).to redirect_to(root_path)
  end
end
