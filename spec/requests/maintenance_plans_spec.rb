require "rails_helper"

RSpec.describe "Maintenance plans", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let!(:plan) do
    MaintenancePlan.create!(company: company, name: "Mantención 10.000 km", interval_km: 10_000, interval_days: 180)
  end

  it "asks to log in first" do
    get maintenance_plans_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list" do
      get maintenance_plans_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mantención 10.000 km")
    end

    it "renders the detail" do
      get maintenance_plan_path(plan)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mantención 10.000 km")
    end

    it "renders the new form" do
      get new_maintenance_plan_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_maintenance_plan_path(plan)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mantención 10.000 km")
    end
  end

  it "doesn't let a chofer see the plans" do
    sign_in create_user(:chofer, company: company)

    get maintenance_plans_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show a plan from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get maintenance_plan_path(plan)

    expect(response).to redirect_to(root_path)
  end
end
