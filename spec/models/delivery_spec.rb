require "rails_helper"

RSpec.describe Delivery do
  let(:company) { create_company }
  let(:driver) { create_user(:chofer, company: company) }
  let(:lomo) { Product.create!(company: company, name: "Lomo vetado", unit: "kg", stock: 100) }
  let(:cajas) { Product.create!(company: company, name: "Hamburguesas", unit: "caja", stock: 10) }

  def build_delivery(lines)
    Delivery.new(company: company, driver: driver, customer: "Restaurante El Toro",
                 lines_attributes: lines.map { |product, quantity| { product_id: product.id, quantity: quantity } })
  end

  it "takes what was delivered out of the stock" do
    delivery = build_delivery([[lomo, 12.5], [cajas, 3]])

    expect(delivery.register(by: driver)).to be(true)
    expect([lomo.reload.stock, cajas.reload.stock]).to eq([87.5, 7])
    expect(ProductMovement.where(delivery: delivery).pluck(:kind, :note).uniq).to eq([["withdrawal", "Entrega a Restaurante El Toro"]])
  end

  it "saves nothing when one product runs short" do
    delivery = build_delivery([[lomo, 10], [cajas, 11]])

    expect(delivery.register(by: driver)).to be(false)
    expect(delivery.errors[:base].first).to eq(
      "No hay stock suficiente de Hamburguesas: se entregan 11 cajas y el sistema tiene 10 cajas. Avisa a bodega para que corrija el stock."
    )
    expect(Delivery.unscoped.count).to eq(0)
    expect([lomo.reload.stock, cajas.reload.stock]).to eq([100, 10])
  end

  it "needs at least one product" do
    delivery = build_delivery([])

    expect(delivery.register(by: driver)).to be(false)
    expect(delivery.errors[:base]).to include("Agrega al menos un producto entregado")
  end

  it "ignores empty rows of the form" do
    delivery = build_delivery([[lomo, 1]])
    delivery.lines_attributes = { "1" => { product_id: "", quantity: "" } }

    expect(delivery.register(by: driver)).to be(true)
    expect(delivery.lines.size).to eq(1)
  end

  it "doesn't take the same product twice" do
    delivery = build_delivery([[lomo, 1], [lomo, 2]])

    expect(delivery.register(by: driver)).to be(false)
    expect(delivery.errors[:base].first).to start_with("Hay productos repetidos: Lomo vetado")
  end

  it "doesn't take products from another company" do
    other = Product.create!(company: create_other_company, name: "Ajeno", unit: "kg", stock: 50)

    expect(build_delivery([[other, 1]]).register(by: driver)).to be(false)
    expect(other.reload.stock).to eq(50)
  end

  it "only takes photos or PDFs up to 10 MB as receipt" do
    delivery = build_delivery([[lomo, 1]])
    delivery.receipt.attach(text_file)

    expect(delivery.register(by: driver)).to be(false)
    expect(delivery.errors[:receipt]).to include("debe ser una foto o un PDF")
  end

  it "gives the stock back when cancelled" do
    admin = company_admin(company)
    delivery = build_delivery([[lomo, 12.5]]).tap { |d| d.register(by: driver) }

    expect(delivery.cancel(by: admin, reason: "Devuelto")).to be(true)
    expect(lomo.reload.stock).to eq(100)
    expect(delivery.reload).to have_attributes(status: "cancelled", cancelled_by: admin, cancel_reason: "Devuelto")
    expect(delivery.cancel(by: admin)).to be(false)
    expect(lomo.reload.stock).to eq(100)
  end
end
