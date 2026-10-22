require "rails_helper"

RSpec.describe "Products", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let!(:product) do
    Product.create!(company: company, name: "Lomo vetado", code: "CAR-001", category: "Carnes", unit: "kg",
                    stock: 100, min_stock: 50, price: 12_990)
  end

  def move(kind, quantity, note: nil)
    post product_product_movements_path(product), params: { product_movement: { kind: kind, quantity: quantity, note: note } }
  end

  it "asks to log in first" do
    get products_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "lists the products, filters them and adds up their value" do
      Product.create!(company: company, name: "Carbón", category: "Abarrotes", unit: "saco", stock: 2, min_stock: 5)

      get products_path
      expect(response.body).to include("Lomo vetado", "Carbón", "$1.299.000")

      get products_path(stock: "bajo")
      expect(response.body).to include("Carbón")
      expect(response.body).not_to include("Lomo vetado")

      get products_path(q: "car-0")
      expect(response.body).to include("Lomo vetado")
      expect(response.body).not_to include("Carbón")
    end

    it "creates a product and records its starting stock" do
      post products_path, params: { product: { name: "Posta negra", unit: "kg", stock: "30.5", category: "Carnes" } }

      created = Product.find_by!(name: "Posta negra")
      expect(response).to redirect_to(product_path(created))
      expect(created.stock).to eq(30.5)
      expect(created.movements.sole).to have_attributes(kind: "adjustment", quantity: 30.5, note: "Stock inicial", user: admin)
    end

    it "creates a product with no stock without a movement" do
      post products_path, params: { product: { name: "Posta negra", unit: "kg", stock: "0" } }

      expect(Product.find_by!(name: "Posta negra").movements).to be_empty
    end

    it "shows the errors of an invalid product" do
      post products_path, params: { product: { name: "Otro", code: "CAR-001", unit: "kg", stock: "1" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Código ya está en uso")
    end

    it "edits the product but not its stock" do
      patch product_path(product), params: { product: { name: "Lomo vetado premium", stock: "999" } }

      expect(response).to redirect_to(product_path(product))
      expect(product.reload).to have_attributes(name: "Lomo vetado premium", stock: 100)
    end

    it "moves the stock and shows the history" do
      move("withdrawal", "35.5", note: "Venta a cliente")
      expect(response).to redirect_to(product_path(product))
      expect(flash[:notice]).to eq("Salida registrada. Stock actual: 64,5 kg.")

      get product_path(product)
      expect(response.body).to include("Venta a cliente", "-35,5 kg")
    end

    it "doesn't take out more than there is" do
      move("withdrawal", "150")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("es mayor que el stock disponible (100 kg)")
      expect(product.reload.stock).to eq(100)
    end

    it "deletes a product with its history" do
      move("entry", "5")

      delete product_path(product)

      expect(response).to redirect_to(products_path)
      expect(Product.unscoped.exists?(product.id)).to be(false)
      expect(ProductMovement.count).to eq(0)
    end
  end

  context "as the bodeguero" do
    before { sign_in create_user(:bodeguero, company: company) }

    it "moves the stock but can't delete products" do
      move("entry", "10")
      expect(product.reload.stock).to eq(110)

      delete product_path(product)
      expect(product.reload).to be_persisted
    end
  end

  context "as the analista" do
    before { sign_in create_user(:analista, company: company) }

    it "sees the products without the form to move stock" do
      get product_path(product)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Mover stock")
    end

    it "can't move the stock" do
      move("withdrawal", "10")

      expect(response).to redirect_to(root_path)
      expect(product.reload.stock).to eq(100)
    end
  end

  %i[chofer mecanico].each do |role|
    it "is hidden from the #{role}" do
      sign_in create_user(role, company: company)

      get products_path

      expect(response).to redirect_to(root_path)
    end
  end

  it "doesn't show or move a product from another company" do
    sign_in company_admin(create_other_company)

    get product_path(product)
    expect(response).to redirect_to(root_path)

    move("withdrawal", "10")
    expect(product.reload.stock).to eq(100)
  end
end
