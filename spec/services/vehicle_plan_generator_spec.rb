require "rails_helper"

RSpec.describe VehiclePlanGenerator do
  let(:company) { create_company }
  let!(:hilux) { create_small_biblioteca }
  let(:vehicle) { create_vehicle(company: company, vehicle_model: hilux) }

  it "creates one plan per frequency with its tasks" do
    result = described_class.new(vehicle).call

    expect(result.plans_created).to eq(2)
    km_plan = MaintenancePlan.unscoped.find_by!(company: company, name: "Toyota Hilux · cada 10.000 km o 6 meses")
    expect(km_plan).to have_attributes(interval_km: 10_000, interval_days: 180, interval_hours: nil, vehicle_model: hilux)
    expect(km_plan.maintenance_task_templates.map(&:description)).to eq(["Reemplazar: Cambio de aceite de motor y filtro", "Reemplazar: Reemplazo de filtro de aire"])
    expect(km_plan.maintenance_task_templates.first.expected_duration_minutes).to eq(48)

    daily = MaintenancePlan.unscoped.find_by!(company: company, name: "Toyota Hilux · cada día")
    expect(daily).to have_attributes(interval_days: 1, interval_km: nil)
  end

  it "adds the parts to the company catalog as compatible with the vehicle" do
    result = described_class.new(vehicle).call

    expect(result).to have_attributes(parts_created: 2, fitments_created: 2)
    oil = Part.unscoped.find_by!(company: company, sku: "CTA-01-R01")
    expect(oil).to have_attributes(name: "Aceite de motor · 5W-30", unit_of_measure: "L", cost: 5_000, stock: 0)
    expect(oil.vehicles).to eq([vehicle])
  end

  it "can run again without duplicating or overwriting what the company changed" do
    described_class.new(vehicle).call
    Part.unscoped.find_by!(sku: "CTA-01-R01").update!(cost: 6_500)

    result = described_class.new(vehicle).call

    expect(result).to have_attributes(plans_created: 0, parts_created: 0, fitments_created: 0)
    expect(MaintenancePlan.unscoped.where(company: company).count).to eq(2)
    expect(Part.unscoped.find_by!(sku: "CTA-01-R01").cost).to eq(6_500)
  end

  it "reuses plans and parts for a second vehicle of the same model" do
    described_class.new(vehicle).call
    second = create_vehicle(company: company, vehicle_model: hilux)

    result = described_class.new(second).call

    expect(result).to have_attributes(plans_created: 0, parts_created: 0, fitments_created: 2)
  end

  it "keeps each company's copy separate" do
    described_class.new(vehicle).call
    other = create_other_company

    result = described_class.new(create_vehicle(company: other, vehicle_model: hilux)).call

    expect(result.plans_created).to eq(2)
    expect(Part.unscoped.where(sku: "CTA-01-R01").pluck(:company_id)).to contain_exactly(company.id, other.id)
  end

  it "uses hours for machinery" do
    retro = VehicleModel.create!(code: "MAQ-01", brand: "Caterpillar", model: "420", meter_unit: "horas")
    retro.plan_items.create!(code: "MAQ-01-TR-01", maintenance_task: MaintenanceTask.find_by!(code: "TR-01"),
                             action: "Reemplazar", frequency_value: 500, frequency_unit: "horas", frequency_months: 6)

    described_class.new(create_vehicle(company: company, vehicle_model: retro)).call

    expect(MaintenancePlan.unscoped.find_by!(name: "Caterpillar 420 · cada 500 h o 6 meses").interval_hours).to eq(500)
  end

  it "needs a library model" do
    expect { described_class.new(create_vehicle(company: company)).call }.to raise_error(ArgumentError)
  end
end
