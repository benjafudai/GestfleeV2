require "rails_helper"

RSpec.describe "Vehicle documents", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let!(:document) do
    VehicleDocument.create!(vehicle: vehicle, doc_type: :revision_tecnica, due_on: Date.new(2027, 3, 31),
                            file: { io: StringIO.new("%PDF-1.4\n%%EOF\n"), filename: "revision.pdf",
                                    content_type: "application/pdf" })
  end

  it "asks to log in first" do
    get new_vehicle_vehicle_document_path(vehicle)

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the new form" do
      get new_vehicle_vehicle_document_path(vehicle)

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_vehicle_vehicle_document_path(vehicle, document)

      expect(response).to have_http_status(:ok)
    end

    it "lists the document on the vehicle's page" do
      get vehicle_path(vehicle)

      expect(response.body).to include(edit_vehicle_vehicle_document_path(vehicle, document))
    end
  end

  it "doesn't let an analista add documents" do
    sign_in create_user(:analista, company: company)

    get new_vehicle_vehicle_document_path(vehicle)

    expect(response).to redirect_to(root_path)
  end

  it "doesn't let another company's admin touch the vehicle's documents" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get edit_vehicle_vehicle_document_path(vehicle, document)

    expect(response).to redirect_to(root_path)
  end
end
