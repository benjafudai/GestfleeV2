require "rails_helper"

RSpec.describe Expense, type: :model do
  let(:company) { create_company }

  def expense(**attrs)
    Expense.new({ company: company, category: :tolls, amount: 3_500, date: Date.current }.merge(attrs))
  end

  it "is valid with an amount, a date and a known currency" do
    expect(expense).to be_valid
  end

  it "rejects a negative amount" do
    expect(expense(amount: -1)).not_to be_valid
  end

  it "needs a date" do
    expect(expense(date: nil)).not_to be_valid
  end

  it "only accepts CLP or USD" do
    expect(expense(currency: "EUR")).not_to be_valid
  end

  it "accepts images and PDFs as supporting documents" do
    record = expense
    record.documents.attach(pdf_file, png_file)

    expect(record).to be_valid
  end

  it "rejects other kinds of files" do
    record = expense
    record.documents.attach(text_file)

    expect(record).not_to be_valid
    expect(record.errors[:documents]).to include("debe ser una imagen o un PDF")
  end

  it "labels categories in Spanish" do
    expect(Expense.human_category(:tolls)).to eq("Peajes")
    expect(Expense.human_category("fuel")).to eq("Combustible")
  end
end
