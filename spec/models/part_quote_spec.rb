require "rails_helper"

RSpec.describe PartQuote, type: :model do
  let(:company) { create_company }
  let(:part) { create_part(company: company) }

  def quote(**attrs)
    PartQuote.new(part: part, supplier: "Repuestos Sur", price: 10_000, quoted_on: Date.current, **attrs)
  end

  it "takes the company from the part" do
    record = quote
    record.save!

    expect(record.company).to eq(company)
  end

  it "needs a supplier and a positive price" do
    record = quote(supplier: "", price: 0)

    expect(record).not_to be_valid
    expect(record.errors[:supplier]).to be_present
    expect(record.errors[:price]).to be_present
  end

  it "only accepts web links" do
    expect(quote(url: "javascript:alert(1)")).not_to be_valid
    expect(quote(url: "https://tienda.cl/filtro")).to be_valid
  end

  it "rejects a part from another company" do
    other = create_other_company

    expect(quote(company: other)).not_to be_valid
  end

  describe "Part#best_quote" do
    it "picks the cheapest recent quote comparing in CLP" do
      allow(CurrencyConverter).to receive(:usd_to_clp).and_return(900)
      quote(supplier: "Caro", price: 20_000).save!
      quote(supplier: "Dólar", price: 15, currency: "USD").save!
      quote(supplier: "Viejo", price: 1_000, quoted_on: 6.months.ago.to_date).save!

      expect(part.reload.best_quote.supplier).to eq("Dólar")
    end

    it "is nil without quotes" do
      expect(part.best_quote).to be_nil
    end
  end
end
