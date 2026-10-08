require "rails_helper"

RSpec.describe "Incident reporting", type: :system do
  let(:password) { "Test-GestFlee-Spec-2026!" }
  # Company requires at least one admin on create.
  let(:company) do
    Company.new(name: "Test Co", rut: "22.222.222-2").tap do |c|
      c.users.build(email: "admin@test.com", role: :admin, password: password)
      c.save!
    end
  end
  let(:vehicle) { Vehicle.create!(company: company, plate: "ZZ9999") }
  let(:chofer) { User.create!(email: "chofer@test.com", password: password, role: :chofer, company: company) }

  before do
    VehicleAssignment.create!(vehicle: vehicle, user: chofer, started_on: 1.day.ago)

    visit new_user_session_path
    fill_in "user_email", with: chofer.email
    fill_in "user_password", with: password
    click_button "Ingresar"
  end

  it "lets a chofer report an incident for their assigned vehicle" do
    visit new_incident_path

    select "Media", from: "incident_severity"
    fill_in "incident_description", with: "Ruido extraño en el motor al frenar."
    click_button "Guardar Incidente"

    expect(page).to have_content("Incidente reportado exitosamente")

    # Assert on raw foreign keys, not the association getters: Vehicle has a
    # `default_scope { where(company: Current.company) }` for multi-tenancy,
    # and Current (thread-local, per-request) is reset once the request that
    # created this record has finished — by the time this line runs outside
    # any request, incident.vehicle would spuriously resolve to nil.
    incident = Incident.last
    expect(incident.vehicle_id).to eq(vehicle.id)
    expect(incident.reporter_id).to eq(chofer.id)
    expect(incident.company_id).to eq(company.id)
    expect(incident.description).to eq("Ruido extraño en el motor al frenar.")
    expect(incident.severity).to eq("medium")
  end

  it "requires a description" do
    visit new_incident_path
    click_button "Guardar Incidente"

    expect(page).to have_content("impidieron guardar el incidente")
    expect(Incident.count).to eq(0)
  end
end
