require 'rails_helper'

RSpec.describe 'Fuel fill management', type: :request do
  let(:company) { create_company }
  let(:vehicle) { create_vehicle(company: company) }
  let(:driver) { create_user(:chofer, company: company) }

  def ticket
    uploaded(png_file('boleta.png'))
  end

  def fill_params(**attrs)
    { liters: 40, cost: 50_000, currency: 'CLP', odometer: 12_000, date: Date.current, ticket: ticket }.merge(attrs)
  end

  def create_fill(user: driver)
    FuelFill.new(company: company, vehicle: vehicle, user: user, liters: 40, cost: 50_000, odometer: 10_000,
                 date: Date.current).tap { |f| f.ticket.attach(png_file) }.tap(&:save!)
  end

  context 'as a driver assigned to the vehicle' do
    before do
      assign_vehicle(driver, vehicle)
      sign_in driver
    end

    it 'registers a fuel fill with its receipt' do
      expect {
        post vehicle_fuel_fills_path(vehicle), params: { fuel_fill: fill_params }
      }.to change(FuelFill.unscoped, :count).by(1).and change(Expense.unscoped, :count).by(1)

      fill = FuelFill.unscoped.last
      expect(fill.user).to eq(driver)
      expect(fill.ticket).to be_attached
      expect(response).to redirect_to(vehicle_fuel_fills_path(vehicle))
    end

    it 'cannot register a fill without a receipt' do
      expect {
        post vehicle_fuel_fills_path(vehicle), params: { fuel_fill: fill_params(ticket: nil) }
      }.not_to change(FuelFill.unscoped, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'cannot edit a fill' do
      fill = create_fill

      patch fuel_fill_path(fill), params: { fuel_fill: { liters: 1 } }

      expect(fill.reload.liters).to eq(40)
      expect(response).to redirect_to(root_path)
    end
  end

  it 'does not let a driver load fuel into a vehicle that is not theirs' do
    sign_in driver

    expect {
      post vehicle_fuel_fills_path(vehicle), params: { fuel_fill: fill_params }
    }.not_to change(FuelFill.unscoped, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  context 'as admin' do
    before do
      assign_vehicle(driver, vehicle)
      sign_in company_admin(company)
    end

    it 'lists the fills of one vehicle' do
      fill = create_fill
      other_vehicle = create_vehicle(company: company)

      get vehicle_fuel_fills_path(other_vehicle)
      expect(response.body).not_to include(fuel_fill_path(fill))

      get vehicle_fuel_fills_path(vehicle)
      expect(response.body).to include(fuel_fill_path(fill))
    end

    it 'corrects and deletes a fill' do
      fill = create_fill

      patch fuel_fill_path(fill), params: { fuel_fill: { liters: 45 } }
      expect(fill.reload.liters).to eq(45)

      expect { delete fuel_fill_path(fill) }.to change(FuelFill.unscoped, :count).by(-1)
      expect(response).to redirect_to(vehicle_fuel_fills_path(vehicle))
    end

    it 'shows the form again when the correction is invalid' do
      fill = create_fill

      patch fuel_fill_path(fill), params: { fuel_fill: { liters: 0 } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
