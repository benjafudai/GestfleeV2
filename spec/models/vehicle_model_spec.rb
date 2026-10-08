require "rails_helper"

RSpec.describe VehicleModel, type: :model do
  let(:company) { create_company }
  let(:hilux) { VehicleModel.create!(code: "CTA-01", category: "Camioneta", brand: "Toyota", model: "Hilux", meter_unit: "km") }

  it "fills brand and model of a vehicle that picks it" do
    vehicle = create_vehicle(company: company, vehicle_model: hilux)

    expect(vehicle).to have_attributes(brand: "Toyota", model: "Hilux")
  end

  it "doesn't overwrite what the user typed" do
    vehicle = create_vehicle(company: company, vehicle_model: hilux, model: "Hilux GR Sport")

    expect(vehicle.model).to eq("Hilux GR Sport")
  end

  it "can't be deleted while a vehicle uses it" do
    create_vehicle(company: company, vehicle_model: hilux)

    expect(hilux.destroy).to be(false)
    expect(hilux.errors).to be_present
  end

  it "only accepts km or horas" do
    expect(VehicleModel.new(code: "X", brand: "X", model: "X", meter_unit: "millas")).not_to be_valid
  end

  it "rejects a negative hour meter on the vehicle" do
    expect(Vehicle.new(company: company, plate: "ZZZZ99", hour_meter: -1)).not_to be_valid
  end
end
