require "rails_helper"

RSpec.describe "Biblioteca in vehicles and plans", type: :request do
  let(:company) { create_company }
  let!(:retro) { VehicleModel.create!(code: "MAQ-01", category: "Maquinaria", brand: "Caterpillar", model: "420", meter_unit: "horas") }

  before { sign_in company_admin(company) }

  it "offers the library models in the vehicle form" do
    get new_vehicle_path

    expect(response.body).to include("Modelo de la biblioteca")
    expect(response.body).to include("Caterpillar 420")
  end

  it "saves the model and the hour meter of a vehicle" do
    post vehicles_path, params: { vehicle: { plate: "MAQX10", vehicle_model_id: retro.id, hour_meter: 1250 } }

    vehicle = Vehicle.unscoped.find_by!(plate: "MAQX10")
    expect(vehicle).to have_attributes(vehicle_model: retro, hour_meter: 1250, brand: "Caterpillar")

    get vehicle_path(vehicle)
    expect(response.body).to include("1.250 h")
    expect(response.body).to include("Maquinaria · Caterpillar 420")
  end

  it "saves and shows a plan measured in hours" do
    post maintenance_plans_path, params: { maintenance_plan: { name: "Servicio 500 h", interval_hours: 500 } }

    plan = MaintenancePlan.unscoped.find_by!(name: "Servicio 500 h")
    expect(plan.interval_hours).to eq(500)

    get maintenance_plan_path(plan)
    expect(response.body).to include("500 h")
  end

  it "rejects a zero interval" do
    post maintenance_plans_path, params: { maintenance_plan: { name: "Malo", interval_hours: 0 } }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
