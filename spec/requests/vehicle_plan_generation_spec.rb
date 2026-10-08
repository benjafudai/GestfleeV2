require "rails_helper"

RSpec.describe "Plans from the biblioteca", type: :request do
  let(:company) { create_company }
  let!(:hilux) { create_small_biblioteca }
  let(:vehicle) { create_vehicle(company: company, vehicle_model: hilux, plate: "HJKL45") }

  it "lets the admin create the plans from the vehicle page" do
    sign_in company_admin(company)

    get vehicle_path(vehicle)
    expect(response.body).to include("Crear plan desde la biblioteca")

    expect { post generate_plan_vehicle_path(vehicle) }.to change { MaintenancePlan.unscoped.count }.by(2)
    expect(response).to redirect_to(vehicle_path(vehicle))
    expect(flash[:notice]).to include("2 planes nuevos")
  end

  it "explains what's missing when the vehicle has no library model" do
    sign_in company_admin(company)
    plain = create_vehicle(company: company)

    post generate_plan_vehicle_path(plain)

    expect(flash[:alert]).to include("modelo de la biblioteca")
  end

  it "doesn't let a mecánico create plans" do
    sign_in create_user(:mecanico, company: company)

    expect { post generate_plan_vehicle_path(vehicle) }.not_to change { MaintenancePlan.unscoped.count }
    expect(response).to redirect_to(root_path)
  end

  it "doesn't reach another company's vehicle" do
    sign_in company_admin(create_other_company)

    expect { post generate_plan_vehicle_path(vehicle) }.not_to change { MaintenancePlan.unscoped.count }
  end

  it "shows the step by step, tools, PPE and reference parts in the plan and the work order" do
    VehiclePlanGenerator.new(vehicle).call
    plan = MaintenancePlan.unscoped.find_by!(name: "Toyota Hilux · cada 10.000 km o 6 meses")
    work_order = WorkOrder.create!(company: company, vehicle: vehicle, maintenance_plan: plan, status: :pending)
    sign_in company_admin(company)

    get maintenance_plan_path(plan)
    expect(response.body).to include("Ver paso a paso", "Retirar el tapón de drenaje", "Llave de filtro", "Guantes nitrilo")
    expect(response.body).to include("Aceite de motor · 5W-30", "Precio estimado")

    get work_order_path(work_order)
    expect(response.body).to include("Guía del plan", "Calentar el motor y apagarlo")
  end
end
