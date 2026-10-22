require "rails_helper"

RSpec.describe Product do
  let(:company) { create_company }

  def build_product(**attrs)
    Product.new(company: company, name: "Lomo vetado", unit: "kg", **attrs)
  end

  it "needs a name and a unit" do
    product = Product.new(company: company)

    expect(product).not_to be_valid
    expect(product.errors.attribute_names).to include(:name, :unit)
  end

  it "doesn't repeat a code inside the same company" do
    build_product(code: "CAR-001").save!

    expect(build_product(code: "CAR-001")).not_to be_valid
    expect(build_product(code: "CAR-001", company: create_other_company)).to be_valid
  end

  it "lets many products go without a code" do
    build_product(code: " ").save!

    expect(build_product(code: "")).to be_valid
  end

  it "is low on stock at or under its minimum" do
    expect(build_product(stock: 50, min_stock: 50)).to be_low_stock
    expect(build_product(stock: 51, min_stock: 50)).not_to be_low_stock
    expect(build_product(stock: 0)).not_to be_low_stock
  end

  it "finds the products under their minimum" do
    low = build_product(name: "Posta", stock: 10, min_stock: 20).tap(&:save!)
    build_product(name: "Lomo", stock: 30, min_stock: 20).save!
    build_product(name: "Carbón", stock: 0).save!

    expect(Product.unscoped.low_stock).to eq([low])
  end
end
