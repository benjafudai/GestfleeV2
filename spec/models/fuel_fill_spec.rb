require "rails_helper"

RSpec.describe FuelFill, type: :model do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:vehicle) { Vehicle.create!(company: company, plate: "AB1234") }

  def fill!(odometer:, liters: 50, user: admin)
    FuelFill.create!(company: company, vehicle: vehicle, user: user, odometer: odometer, liters: liters,
                     cost: liters * 1_300, date: Date.current, ticket: png_file("boleta.png"))
  end

  describe "km per liter" do
    it "is left empty on the vehicle's first fill" do
      expect(fill!(odometer: 10_000).km_per_liter).to be_nil
    end

    it "is the distance since the previous fill divided by the liters" do
      fill!(odometer: 10_000)

      expect(fill!(odometer: 10_500, liters: 50).km_per_liter).to eq(10)
    end

    it "ignores the fills of other vehicles" do
      other_vehicle = Vehicle.create!(company: company, plate: "CD5678")
      FuelFill.create!(company: company, vehicle: other_vehicle, user: admin, odometer: 9_000, liters: 40,
                       cost: 52_000, date: Date.current, ticket: png_file("boleta.png"))

      expect(fill!(odometer: 10_000).km_per_liter).to be_nil
    end
  end

  it "records the fill as a fuel expense" do
    fuel_fill = fill!(odometer: 10_000, liters: 40)

    expect(fuel_fill.expense).to have_attributes(company: company, vehicle: vehicle, category: "fuel",
                                                 amount: 52_000, date: Date.current)
  end

  describe "consumption alerts" do
    let!(:analista) { create_user(:analista, company: company) }
    let!(:chofer) { create_user(:chofer, company: company) }

    before do
      fill!(odometer: 10_000)
      fill!(odometer: 10_500) # 10 km/l
      fill!(odometer: 11_000) # 10 km/l
    end

    it "warns the admins and analysts when the yield drops below the threshold" do
      expect { fill!(odometer: 11_250) }.to change(Notification, :count).by(2) # 5 km/l, limit is 8 km/l (20% under 10)

      expect(Notification.last(2).map(&:user)).to contain_exactly(admin, analista)
      expect(Notification.last.title).to eq("Alerta de Consumo: AB1234")
    end

    it "stays quiet for a normal fill" do
      expect { fill!(odometer: 11_450) }.not_to change(Notification, :count) # 9 km/l
    end

    it "uses the company's own threshold" do
      company.update!(fuel_anomaly_threshold: 60) # limit drops to 4 km/l

      expect { fill!(odometer: 11_250) }.not_to change(Notification, :count)
    end
  end

  describe "ticket photo" do
    it "is required" do
      fuel_fill = FuelFill.new(company: company, vehicle: vehicle, user: admin, odometer: 1, liters: 1, cost: 1, date: Date.current)

      expect(fuel_fill).not_to be_valid
      expect(fuel_fill.errors[:ticket]).to include("la fotografía de la boleta es obligatoria para registrar cargas.")
    end

    it "must be an image" do
      fuel_fill = FuelFill.new(company: company, vehicle: vehicle, user: admin, odometer: 1, liters: 1, cost: 1,
                               date: Date.current, ticket: pdf_file)

      expect(fuel_fill).not_to be_valid
      expect(fuel_fill.errors[:ticket]).to include("debe ser una imagen (jpg, png, etc.)")
    end
  end

  describe "a chofer" do
    let(:chofer) { create_user(:chofer, company: company) }

    it "can only register fuel for the vehicle assigned to them" do
      expect { fill!(odometer: 10_000, user: chofer) }
        .to raise_error(ActiveRecord::RecordInvalid, /debe ser el que tienes asignado actualmente/)
    end

    it "can register fuel for their assigned vehicle" do
      VehicleAssignment.create!(vehicle: vehicle, user: chofer, started_on: Date.current)

      expect(fill!(odometer: 10_000, user: chofer)).to be_persisted
    end
  end
end
