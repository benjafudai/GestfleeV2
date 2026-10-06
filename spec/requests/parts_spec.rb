require "rails_helper"

RSpec.describe "Parts", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let!(:part) do
    Part.create!(company: company, sku: "FLT-001", name: "Filtro de aceite", unit_of_measure: "unidad", stock: 5, cost: 12_000)
  end

  it "asks to log in first" do
    get parts_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list" do
      get parts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Filtro de aceite")
    end

    it "renders the detail" do
      get part_path(part)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FLT-001")
    end

    it "renders the new form" do
      get new_part_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_part_path(part)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Filtro de aceite")
    end
  end

  it "doesn't let a chofer see the inventory" do
    sign_in create_user(:chofer, company: company)

    get parts_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show a part from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get part_path(part)

    expect(response).to redirect_to(root_path)
  end
end
