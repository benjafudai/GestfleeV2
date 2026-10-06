require "rails_helper"

RSpec.describe Vehicle, type: :model do
  let(:company) { create_company }

  it "needs a plate" do
    expect(Vehicle.new(company: company)).not_to be_valid
  end

  it "doesn't repeat a plate, even across companies" do
    Vehicle.create!(company: company, plate: "AB1234")
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")

    expect(Vehicle.new(company: other, plate: "AB1234")).not_to be_valid
  end

  it "only accepts years after 1950, or none" do
    expect(Vehicle.new(company: company, plate: "AB1234", year: 1950)).not_to be_valid
    expect(Vehicle.new(company: company, plate: "AB1234", year: 2019)).to be_valid
    expect(Vehicle.new(company: company, plate: "AB1234", year: nil)).to be_valid
  end
end
