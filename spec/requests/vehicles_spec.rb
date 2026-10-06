require "rails_helper"

RSpec.describe "Vehicles", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let!(:vehicle) { Vehicle.create!(company: company, plate: "AB1234", brand: "Volvo") }

  it "asks to log in first" do
    get vehicles_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list" do
      get vehicles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AB1234")
    end

    it "renders the detail" do
      get vehicle_path(vehicle)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AB1234")
    end

    it "renders the new form" do
      get new_vehicle_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_vehicle_path(vehicle)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AB1234")
    end
  end

  it "doesn't let a chofer see the fleet" do
    sign_in create_user(:chofer, company: company)

    get vehicles_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show a vehicle from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get vehicle_path(vehicle)

    expect(response).to redirect_to(root_path)
  end
end
