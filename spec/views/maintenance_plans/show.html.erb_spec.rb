require 'rails_helper'

RSpec.describe "maintenance_plans/show", type: :view do
  before(:each) do
    assign(:maintenance_plan, MaintenancePlan.create!(
      name: "Name",
      description: "Description",
      interval_km: 2,
      interval_days: 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end
