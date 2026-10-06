require "rails_helper"

RSpec.describe UserDocument, type: :model do
  let(:company) { create_company }
  let(:chofer) { create_user(:chofer, company: company) }

  def document(**attrs)
    UserDocument.new({ user: chofer, doc_type: :licencia_conducir, due_on: Date.current + 100 }.merge(attrs))
  end

  it "accepts a PDF or an image" do
    expect(document(file: pdf_file)).to be_valid
    expect(document(file: png_file)).to be_valid
  end

  it "needs a file" do
    record = document

    expect(record).not_to be_valid
    expect(record.errors[:file]).to include("debe adjuntar un archivo")
  end

  it "rejects other kinds of files" do
    record = document(file: text_file)

    expect(record).not_to be_valid
    expect(record.errors[:file]).to include("debe ser una imagen o un PDF")
  end

  it "needs a due date" do
    expect(document(file: pdf_file, due_on: nil)).not_to be_valid
  end
end
