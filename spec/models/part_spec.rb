require "rails_helper"

RSpec.describe Part, type: :model do
  let(:company) { create_company }

  def part(company: self.company, **attrs)
    Part.new({ company: company, sku: "FLT-001", name: "Filtro", unit_of_measure: "unidad", stock: 5, cost: 1000 }.merge(attrs))
  end

  it "needs a SKU, a name and a unit of measure" do
    record = part(sku: nil, name: nil, unit_of_measure: nil)

    expect(record).not_to be_valid
    expect(record.errors.attribute_names).to include(:sku, :name, :unit_of_measure)
  end

  it "doesn't repeat a SKU within the same company" do
    part.save!

    expect(part).not_to be_valid
  end

  it "allows the same SKU in another company" do
    part.save!
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")

    expect(part(company: other)).to be_valid
  end

  it "rejects negative stock or cost" do
    expect(part(stock: -1)).not_to be_valid
    expect(part(cost: -1)).not_to be_valid
  end

  it "only accepts CLP or USD" do
    expect(part(currency: "EUR")).not_to be_valid
  end
end
