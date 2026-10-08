require "rails_helper"

RSpec.describe Incident, type: :model do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }

  def incident(**attrs)
    Incident.new({ company: company, vehicle: vehicle, reporter: admin, description: "Pinchazo" }.merge(attrs))
  end

  it "starts as pending with low severity" do
    expect(incident).to have_attributes(status: "pending", severity: "low")
  end

  it "needs a description" do
    expect(incident(description: "")).not_to be_valid
  end

  it "only accepts images as photos" do
    record = incident
    record.photos.attach(png_file, pdf_file)

    expect(record).not_to be_valid
    expect(record.errors[:photos]).to include("debe ser una imagen (jpg, png, etc.)")
  end

  it "lets a chofer report only on the vehicle assigned to them" do
    chofer = create_user(:chofer, company: company)

    expect(incident(reporter: chofer)).not_to be_valid

    VehicleAssignment.create!(vehicle: vehicle, user: chofer, started_on: Date.current)
    expect(incident(reporter: chofer.reload)).to be_valid
  end
end
