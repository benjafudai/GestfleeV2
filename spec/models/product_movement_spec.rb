require "rails_helper"

RSpec.describe ProductMovement do
  let(:company) { create_company }
  let(:product) { Product.create!(company: company, name: "Lomo vetado", unit: "kg", stock: 100) }

  def move(kind, quantity)
    ProductMovement.new(product: product, kind: kind, quantity: quantity)
  end

  it "adds an entry to the stock" do
    movement = move(:entry, 20.5)

    expect(movement.apply).to be(true)
    expect(product.reload.stock).to eq(120.5)
    expect(movement.stock_after).to eq(120.5)
  end

  it "takes a withdrawal out of the stock" do
    move(:withdrawal, 30).apply

    expect(product.reload.stock).to eq(70)
  end

  it "replaces the stock with an adjustment" do
    move(:adjustment, 42).apply

    expect(product.reload.stock).to eq(42)
  end

  it "doesn't take out more than there is" do
    movement = move(:withdrawal, 100.5)

    expect(movement.apply).to be(false)
    expect(movement.errors[:quantity]).to eq(["es mayor que el stock disponible (100 kg)"])
    expect(product.reload.stock).to eq(100)
    expect(ProductMovement.count).to eq(0)
  end

  it "needs a positive quantity for entries and withdrawals" do
    expect(move(:entry, 0).apply).to be(false)
    expect(move(:adjustment, 0).apply).to be(true)
    expect(product.reload.stock).to eq(0)
  end

  it "rejects an unknown kind instead of failing" do
    movement = ProductMovement.new(product: product, kind: "regalo", quantity: 1)

    expect(movement.apply).to be(false)
    expect(movement.errors.attribute_names).to include(:kind)
  end
end
