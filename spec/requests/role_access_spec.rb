require "rails_helper"

# Qué pantallas puede abrir cada rol. Un rol sin permiso es redirigido al
# inicio con "No autorizado." (ver ApplicationController).
RSpec.describe "Role access", type: :request do
  ROLES = %i[superadmin admin chofer mecanico analista].freeze

  ALLOWED = {
    "/dashboard"                 => ROLES,
    "/notifications"             => ROLES,
    "/incidents"                 => ROLES,
    "/incidents/new"             => %i[superadmin admin chofer],
    "/alerts"                    => %i[superadmin admin analista],
    "/vehicles"                  => %i[superadmin admin analista],
    "/vehicles/new"              => %i[superadmin admin],
    "/expenses"                  => %i[superadmin admin analista],
    "/expenses/new"              => %i[superadmin admin],
    "/fuel_fills"                => %i[superadmin admin chofer analista],
    "/checklist_templates"       => %i[superadmin admin analista],
    "/checklist_templates/new"   => %i[superadmin admin],
    "/checklist_submissions"     => %i[superadmin admin chofer analista],
    "/checklist_submissions/new" => %i[chofer],
    "/work_orders"               => %i[superadmin admin mecanico],
    "/work_orders/new"           => %i[superadmin admin mecanico],
    "/maintenance_plans"         => %i[superadmin admin mecanico],
    "/maintenance_plans/new"     => %i[superadmin admin],
    "/parts"                     => %i[superadmin admin mecanico analista],
    "/parts/new"                 => %i[superadmin admin],
    "/supply_requests"           => %i[superadmin admin mecanico analista],
    "/supply_requests/new"       => %i[superadmin admin mecanico],
    "/users"                     => %i[superadmin admin],
    "/users/new"                 => %i[superadmin admin],
    "/password_reset_requests"   => %i[superadmin],
    "/companies"                 => %i[superadmin],
    "/companies/new"             => %i[superadmin]
  }.freeze

  let(:company) do
    create_company.tap { |c| c.update!(has_mechanic: true, has_analyst: true) }
  end

  ROLES.each do |role|
    context "as #{role}" do
      before do
        user = role == :admin ? company_admin(company) : create_user(role, company: (company unless role == :superadmin))
        sign_in user
      end

      ALLOWED.each do |path, roles|
        if roles.include?(role)
          it "can open #{path}" do
            get path
            expect(response).to have_http_status(:ok)
          end
        else
          it "is redirected away from #{path}" do
            get path
            expect(response).to redirect_to(root_path)
          end
        end
      end
    end
  end
end
