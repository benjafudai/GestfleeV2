require "rails_helper"

RSpec.describe VehicleDocument, type: :model do
  let(:company) { create_company }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }

  def document(**attrs)
    VehicleDocument.new({ vehicle: vehicle, doc_type: :seguro, due_on: Date.current + 100 }.merge(attrs))
  end

  it "is valid with a type, a due date and a PDF" do
    expect(document(file: pdf_file)).to be_valid
  end

  it "needs the PDF" do
    record = document

    expect(record).not_to be_valid
    expect(record.errors[:file]).to include("debe adjuntar un archivo PDF")
  end

  it "rejects files that aren't PDFs" do
    record = document(file: png_file)

    expect(record).not_to be_valid
    expect(record.errors[:file]).to include("debe ser un archivo PDF")
  end

  it "needs a due date" do
    expect(document(file: pdf_file, due_on: nil)).not_to be_valid
  end
end
