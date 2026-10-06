require "rails_helper"

RSpec.describe "Incidents", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }
  let!(:incident) do
    Incident.create!(company: company, vehicle: vehicle, reporter: admin, severity: :high,
                     description: "Pinchazo en ruta 5")
  end

  it "asks to log in first" do
    get incidents_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list" do
      get incidents_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AB1234")
    end

    it "renders the detail" do
      get incident_path(incident)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pinchazo en ruta 5")
    end

    it "renders the new form" do
      get new_incident_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_incident_path(incident)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pinchazo en ruta 5")
    end
  end

  it "doesn't show an incident from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get incident_path(incident)

    expect(response).to redirect_to(root_path)
  end
end
