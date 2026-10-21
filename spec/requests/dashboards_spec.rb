require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:company) { create_company }

  it "asks to log in first" do
    get dashboard_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows the public home page to visitors" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Toda su flota en un solo lugar")
    expect(response.body).to include(new_user_session_path)
    expect(response.body).not_to include("Solicitar una demo")
  end

  it "offers a demo on the home page when a contact is set" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("CONTACT_WHATSAPP").and_return("+56 9 1234 5678")

    get root_path

    expect(response.body).to include("Solicitar una demo")
    expect(response.body).to include("https://wa.me/56912345678")
  end

  it "runs the document expiry check on the first visit of the day" do
    vehicle = Vehicle.create!(company: company, plate: "AB1234")
    document = VehicleDocument.create!(vehicle: vehicle, doc_type: :revision_tecnica, due_on: Date.today + 10, file: pdf_file)
    ComplianceChecker.instance_variable_set(:@last_run_on, nil)
    other_company = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in create_user(:chofer, company: other_company) # de otra empresa: igual revisa todas

    Rails.configuration.x.daily_compliance_check = true
    begin
      get root_path
    ensure
      Rails.configuration.x.daily_compliance_check = false
    end

    expect(document.reload).to be_expiring
    expect(Notification.where(user: company_admin(company)).count).to eq(1)
  end

  # Each role gets its own dashboard; every one of them has to render.
  %i[admin chofer mecanico analista bodeguero].each do |role|
    it "renders for the #{role}" do
      user = role == :admin ? company_admin(company) : create_user(role, company: company)
      sign_in user

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  it "renders for a superadmin" do
    sign_in create_user(:superadmin)

    get dashboard_path

    expect(response).to have_http_status(:ok)
  end
end
