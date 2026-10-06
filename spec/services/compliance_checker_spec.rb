require "rails_helper"

RSpec.describe ComplianceChecker do
  let(:company) { create_company }
  let!(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }

  def vehicle_document(due_on)
    VehicleDocument.create!(vehicle: vehicle, doc_type: :revision_tecnica, due_on: due_on, file: pdf_file)
  end

  it "marks a document past its due date as expired and warns the admins" do
    document = vehicle_document(Date.today - 1)

    expect { described_class.call }.to change { Notification.where(user: admin).count }.by(1)

    expect(document.reload).to be_expired
    expect(Notification.last.title).to eq("Documento Vencido: AB1234")
  end

  it "marks a document due within 30 days as expiring and warns the admins" do
    document = vehicle_document(Date.today + 10)

    described_class.call

    expect(document.reload).to be_expiring
    expect(Notification.last.title).to eq("Documento por vencer: AB1234")
  end

  it "leaves a document due later as ok, without warning anyone" do
    document = vehicle_document(Date.today + 90)

    expect { described_class.call }.not_to change(Notification, :count)
    expect(document.reload).to be_ok
  end

  it "warns only once while the status doesn't change" do
    vehicle_document(Date.today - 1)

    expect { 2.times { described_class.call } }.to change(Notification, :count).by(1)
  end

  it "puts a renewed document back to ok" do
    document = vehicle_document(Date.today - 1)
    described_class.call

    document.update!(due_on: Date.today + 365)
    described_class.call

    expect(document.reload).to be_ok
  end

  it "checks people's documents too" do
    chofer = create_user(:chofer, company: company, email: "chofer@uno.cl")
    document = UserDocument.create!(user: chofer, doc_type: :licencia_conducir, due_on: Date.today + 5, file: pdf_file)

    described_class.call

    expect(document.reload).to be_expiring
    expect(Notification.last.title).to eq("Documento por vencer: chofer@uno.cl")
  end
end
