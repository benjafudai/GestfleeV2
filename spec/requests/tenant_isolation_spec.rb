require "rails_helper"

# Un usuario nunca debe ver ni modificar datos de otra empresa.
RSpec.describe "Tenant isolation", type: :request do
  let(:company) { create_company }
  let(:other_company) { create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl") }
  let!(:own_vehicle) { create_vehicle(company: company, plate: "OWN001") }
  let!(:foreign_vehicle) { create_vehicle(company: other_company, plate: "FOR001") }

  before { sign_in company_admin(company) }

  it "lists only vehicles of the user's company" do
    get vehicles_path

    expect(response.body).to include("OWN001")
    expect(response.body).not_to include("FOR001")
  end

  it "does not show a vehicle of another company" do
    get vehicle_path(foreign_vehicle)

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("El recurso solicitado no existe o no tienes acceso a él.")
  end

  it "does not update a vehicle of another company" do
    patch vehicle_path(foreign_vehicle), params: { vehicle: { brand: "Hackeado" } }

    expect(response).to redirect_to(root_path)
    expect(foreign_vehicle.reload.brand).not_to eq("Hackeado")
  end

  it "does not delete a vehicle of another company" do
    expect { delete vehicle_path(foreign_vehicle) }.not_to change(Vehicle.unscoped, :count)
  end

  it "lets a superadmin see vehicles of every company" do
    sign_in create_user(:superadmin)
    get vehicles_path

    expect(response.body).to include("OWN001", "FOR001")
  end
end
