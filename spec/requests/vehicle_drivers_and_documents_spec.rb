require 'rails_helper'

RSpec.describe 'Vehicle drivers and documents', type: :request do
  let(:company) { create_company }
  let(:vehicle) { create_vehicle(company: company) }
  let(:driver) { create_user(:chofer, company: company) }

  def pdf(name = 'revision.pdf')
    uploaded(pdf_file(name))
  end

  context 'as admin' do
    before { sign_in company_admin(company) }

    it 'assigns a driver and ends the assignment' do
      post vehicle_vehicle_assignments_path(vehicle),
           params: { vehicle_assignment: { user_id: driver.id, started_on: Date.current } }

      assignment = vehicle.vehicle_assignments.sole
      expect(driver.reload.active_assignment).to eq(assignment)
      expect(response).to redirect_to(vehicle_path(vehicle))

      delete vehicle_vehicle_assignment_path(vehicle, assignment)

      expect(assignment.reload.ended_on).to eq(Date.current)
      expect(driver.reload.active_assignment).to be_nil
    end

    it 'shows the form again when the driver is already busy' do
      assign_vehicle(driver, create_vehicle(company: company))

      post vehicle_vehicle_assignments_path(vehicle),
           params: { vehicle_assignment: { user_id: driver.id, started_on: Date.current } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('ya está asignado a otro vehículo actualmente')
    end

    it 'only offers drivers of the vehicle company' do
      outsider = create_user(:chofer, company: create_other_company)
      driver

      get new_vehicle_vehicle_assignment_path(vehicle)

      expect(response.body).to include(driver.email)
      expect(response.body).not_to include(outsider.email)
    end

    it 'uploads, updates and deletes a document' do
      post vehicle_vehicle_documents_path(vehicle),
           params: { vehicle_document: { doc_type: 'revision_tecnica', due_on: Date.current + 10, file: pdf } }
      document = vehicle.vehicle_documents.sole

      patch vehicle_vehicle_document_path(vehicle, document), params: { vehicle_document: { due_on: Date.current + 365 } }
      expect(document.reload.due_on).to eq(Date.current + 365)

      expect { delete vehicle_vehicle_document_path(vehicle, document) }.to change(VehicleDocument, :count).by(-1)
      expect(response).to redirect_to(vehicle_path(vehicle))
    end

    it 'only accepts PDF documents' do
      image = uploaded(png_file('foto.png'))

      expect {
        post vehicle_vehicle_documents_path(vehicle),
             params: { vehicle_document: { doc_type: 'seguro', due_on: Date.current, file: image } }
      }.not_to change(VehicleDocument, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it 'does not let an analyst assign drivers' do
    sign_in create_user(:analista, company: company)

    post vehicle_vehicle_assignments_path(vehicle),
         params: { vehicle_assignment: { user_id: driver.id, started_on: Date.current } }

    expect(VehicleAssignment.count).to eq(0)
    expect(response).to redirect_to(root_path)
  end
end
