require "rails_helper"

RSpec.describe "Supply requests", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let(:part) do
    Part.create!(company: company, sku: "FLT-001", name: "Filtro de aceite", unit_of_measure: "unidad", stock: 5, cost: 12_000)
  end
  let!(:supply_request) do
    SupplyRequest.create!(company: company, vehicle: vehicle, user: admin, status: :requested,
                          supply_request_lines_attributes: [{ part_id: part.id, quantity: 2 }])
  end

  it "asks to log in first" do
    get supply_requests_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list" do
      get supply_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AB1234")
    end

    it "renders the detail" do
      get supply_request_path(supply_request)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Filtro de aceite")
    end

    it "renders the new form" do
      get new_supply_request_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_supply_request_path(supply_request)

      expect(response).to have_http_status(:ok)
    end
  end

  it "doesn't let a chofer see the requests" do
    sign_in create_user(:chofer, company: company)

    get supply_requests_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show a request from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get supply_request_path(supply_request)

    expect(response).to redirect_to(root_path)
  end
end
