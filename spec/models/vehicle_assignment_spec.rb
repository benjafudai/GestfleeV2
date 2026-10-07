require 'rails_helper'

RSpec.describe VehicleAssignment, type: :model do
  let(:company) { create_company }
  let(:vehicle) { create_vehicle(company: company) }
  let(:driver) { create_user(:chofer, company: company) }

  it 'assigns a driver to a vehicle' do
    assignment = assign_vehicle(driver, vehicle)

    expect(driver.active_assignment).to eq(assignment)
    expect(VehicleAssignment.active).to include(assignment)
  end

  it 'only accepts drivers' do
    assignment = VehicleAssignment.new(user: create_user(:mecanico, company: company), vehicle: vehicle,
                                       started_on: Date.current)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:user]).to include('debe tener rol de chofer')
  end

  it 'rejects a driver from another company' do
    outsider = create_user(:chofer, company: create_other_company)
    assignment = VehicleAssignment.new(user: outsider, vehicle: vehicle, started_on: Date.current)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:user]).to include('debe pertenecer a la misma empresa que el vehículo')
  end

  it 'does not give a vehicle two drivers at once' do
    assign_vehicle(driver, vehicle)
    assignment = VehicleAssignment.new(user: create_user(:chofer, company: company), vehicle: vehicle,
                                       started_on: Date.current)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:vehicle]).to include('ya tiene un chofer asignado actualmente')
  end

  it 'does not give a driver two vehicles at once' do
    assign_vehicle(driver, vehicle)
    assignment = VehicleAssignment.new(user: driver, vehicle: create_vehicle(company: company), started_on: Date.current)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:user]).to include('ya está asignado a otro vehículo actualmente')
  end

  it 'allows a new driver once the previous assignment has ended' do
    assign_vehicle(driver, vehicle).update!(ended_on: Date.current)

    expect(VehicleAssignment.historical.count).to eq(1)
    expect { assign_vehicle(create_user(:chofer, company: company), vehicle) }.not_to raise_error
  end

  it 'cannot end before it started' do
    assignment = assign_vehicle(driver, vehicle)

    expect(assignment.update(ended_on: Date.current - 1)).to be(false)
    expect(assignment.errors[:ended_on]).to include('no puede ser anterior a la fecha de inicio')
  end
end
