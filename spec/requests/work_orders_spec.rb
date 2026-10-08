require "rails_helper"

RSpec.describe "Work orders", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let!(:work_order) do
    WorkOrder.create!(company: company, vehicle: vehicle, status: :pending, notes: "Cambio de pastillas de freno")
  end

  it "asks to log in first" do
    get work_orders_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list" do
      get work_orders_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AB1234")
    end

    it "renders the detail" do
      get work_order_path(work_order)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cambio de pastillas de freno")
    end

    it "renders the new form" do
      get new_work_order_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_work_order_path(work_order)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cambio de pastillas de freno")
    end
  end

  it "doesn't let a chofer see the work orders" do
    sign_in create_user(:chofer, company: company)

    get work_orders_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show a work order from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get work_order_path(work_order)

    expect(response).to redirect_to(root_path)
  end
end
