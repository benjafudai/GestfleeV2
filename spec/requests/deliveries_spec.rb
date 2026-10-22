require "rails_helper"

RSpec.describe "Deliveries", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:driver) { create_user(:chofer, company: company, email: "chofer@uno.cl") }
  let!(:lomo) { Product.create!(company: company, name: "Lomo vetado", unit: "kg", stock: 100) }

  def deliver(quantity, customer: "Restaurante El Toro", **extra)
    post deliveries_path, params: { delivery: { customer: customer,
                                                lines_attributes: { "0" => { product_id: lomo.id, quantity: quantity } }, **extra } }
  end

  def registered(by:, customer: "Cliente previo")
    Delivery.new(company: company, driver: by, customer: customer,
                 lines_attributes: [{ product_id: lomo.id, quantity: 10 }]).tap { |d| d.register(by: by) }
  end

  context "as a driver" do
    before { sign_in driver }

    it "registers a delivery with the assigned vehicle and takes it out of the stock" do
      vehicle = create_vehicle(company: company, plate: "AB1234")
      assign_vehicle(driver, vehicle)

      deliver("12.5", receipt: uploaded(png_file))

      delivery = Delivery.unscoped.last
      expect(response).to redirect_to(delivery_path(delivery))
      expect(delivery).to have_attributes(driver: driver, vehicle: vehicle, customer: "Restaurante El Toro")
      expect(delivery.receipt).to be_attached
      expect(lomo.reload.stock).to eq(87.5)
    end

    it "can't register it in another driver's name" do
      other = create_user(:chofer, company: company)

      deliver("1", driver_id: other.id)

      expect(Delivery.unscoped.last.driver).to eq(driver)
    end

    it "explains when there isn't enough stock" do
      deliver("150")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("No hay stock suficiente de Lomo vetado")
      expect(lomo.reload.stock).to eq(100)
    end

    it "only sees their own deliveries" do
      mine = registered(by: driver)
      theirs = registered(by: create_user(:chofer, company: company))

      get deliveries_path
      expect(response.body).to include("Mis entregas")

      get delivery_path(mine)
      expect(response).to have_http_status(:ok)

      get delivery_path(theirs)
      expect(response).to redirect_to(root_path)
    end

    it "can't cancel a delivery" do
      delivery = registered(by: driver)

      patch cancel_delivery_path(delivery)

      expect(delivery.reload).to be_delivered
      expect(lomo.reload.stock).to eq(90)
    end

    it "sees the deliveries menu only when the company has products" do
      get dashboard_path
      expect(response.body).to include("Mis entregas", "Registrar entrega")

      lomo.destroy!
      get dashboard_path
      expect(response.body).not_to include("Mis entregas")
    end
  end

  context "as the admin" do
    before { sign_in admin }

    it "lists every delivery and filters by driver" do
      registered(by: driver, customer: "Carnicería Uno")
      registered(by: create_user(:chofer, company: company), customer: "Carnicería Dos")

      get deliveries_path
      expect(response.body).to include("Carnicería Uno", "Carnicería Dos")

      get deliveries_path(driver_id: driver.id)
      expect(response.body).to include("Carnicería Uno")
      expect(response.body).not_to include("Carnicería Dos")
    end

    it "registers a delivery for a driver" do
      deliver("5", driver_id: driver.id)

      expect(Delivery.unscoped.last.driver).to eq(driver)
    end

    it "cancels a delivery and gives the stock back" do
      delivery = registered(by: driver)

      patch cancel_delivery_path(delivery), params: { cancel_reason: "Cliente devolvió" }

      expect(response).to redirect_to(delivery_path(delivery))
      expect(delivery.reload).to have_attributes(status: "cancelled", cancel_reason: "Cliente devolvió")
      expect(lomo.reload.stock).to eq(100)
    end

    it "can't delete a product that was delivered" do
      registered(by: driver)

      delete product_path(lomo)

      expect(response).to redirect_to(product_path(lomo))
      expect(flash[:alert]).to start_with("No se puede eliminar")
      expect(lomo.reload).to be_persisted
    end
  end

  it "doesn't show deliveries to the mecanico" do
    sign_in create_user(:mecanico, company: company)

    get deliveries_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show a delivery from another company" do
    delivery = registered(by: driver)
    sign_in company_admin(create_other_company)

    get delivery_path(delivery)

    expect(response).to redirect_to(root_path)
  end

  it "doesn't let another company's driver use these products" do
    sign_in create_user(:chofer, company: create_other_company)

    deliver("1")

    expect(response).to have_http_status(:unprocessable_content)
    expect(lomo.reload.stock).to eq(100)
  end
end
