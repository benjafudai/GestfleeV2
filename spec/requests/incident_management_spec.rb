require 'rails_helper'

RSpec.describe 'Incident management', type: :request do
  let(:company) { with_modules(create_company, has_mechanic: true) }
  let(:vehicle) { create_vehicle(company: company) }
  let(:driver) { create_user(:chofer, company: company) }

  def photo(name = 'golpe.png')
    uploaded(png_file(name))
  end

  def create_incident
    Incident.new(company: company, vehicle: vehicle, reporter: driver, description: 'Pinchazo').tap do |incident|
      incident.photos.attach(png_file)
      incident.save!
    end
  end

  before { assign_vehicle(driver, vehicle) }

  context 'as driver' do
    before { sign_in driver }

    it 'reports an incident with photos, always as pending' do
      expect {
        post incidents_path, params: {
          incident: { vehicle_id: vehicle.id, description: 'Choque leve', severity: 'high', status: 'resolved',
                      photos: [ '', photo ] }
        }
      }.to change(Incident.unscoped, :count).by(1)

      incident = Incident.unscoped.last
      expect(incident.reporter).to eq(driver)
      expect(incident).to be_pending
      expect(incident).to be_high
      expect(incident.photos).to be_attached
      expect(response).to redirect_to(incident_path(incident))
    end

    it 'cannot attach something that is not a photo' do
      file = uploaded(text_file('nota.txt'))

      expect {
        post incidents_path, params: { incident: { vehicle_id: vehicle.id, description: 'x', photos: [ file ] } }
      }.not_to change(Incident.unscoped, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'cannot report on a vehicle that is not assigned to them' do
      other = create_vehicle(company: company)

      expect {
        post incidents_path, params: { incident: { vehicle_id: other.id, description: 'x' } }
      }.not_to change(Incident.unscoped, :count)
    end

    it 'cannot change the status' do
      incident = create_incident

      patch incident_path(incident), params: { incident: { status: 'resolved' } }

      expect(incident.reload).to be_pending
      expect(response).to redirect_to(root_path)
    end
  end

  context 'as mechanic' do
    before { sign_in create_user(:mecanico, company: company) }

    it 'changes the status and keeps the driver photos' do
      incident = create_incident

      patch incident_path(incident), params: { incident: { status: 'in_review', photos: [ '' ] } }

      expect(incident.reload).to be_in_review
      expect(incident.photos.count).to eq(1)
    end

    it 'adds photos next to the existing ones' do
      incident = create_incident

      patch incident_path(incident), params: { incident: { photos: [ '', photo('reparado.png') ] } }

      expect(incident.reload.photos.count).to eq(2)
    end

    it 'shows the form again when the update is invalid' do
      incident = create_incident

      patch incident_path(incident), params: { incident: { description: '' } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
