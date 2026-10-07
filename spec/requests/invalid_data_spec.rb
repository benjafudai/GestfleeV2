require "rails_helper"

RSpec.describe "Invalid data handling", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let!(:vehicle) { Vehicle.create!(company: company, plate: "AB1234", brand: "Volvo", status: :active) }

  before { sign_in admin }

  it "redirects back with a message when an enum gets a value it doesn't have" do
    patch vehicle_path(vehicle), params: { vehicle: { status: "volando" } },
                                 headers: { "HTTP_REFERER" => edit_vehicle_path(vehicle) }

    expect(response).to redirect_to(edit_vehicle_path(vehicle))
    expect(flash[:alert]).to eq("Datos inválidos: uno de los valores seleccionados no es válido.")
    expect(vehicle.reload).to be_active
  end

  it "doesn't hide any other ArgumentError" do
    allow_any_instance_of(VehiclesController).to receive(:index).and_raise(ArgumentError, "fallo interno")

    expect { get vehicles_path }.to raise_error(ArgumentError, "fallo interno")
  end

  it "runs Rack::Attack once per request" do
    expect(Rails.application.middleware.count { |middleware| middleware.klass == Rack::Attack }).to eq(1)
  end
end
