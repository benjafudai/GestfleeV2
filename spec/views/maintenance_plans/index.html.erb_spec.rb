require 'rails_helper'

RSpec.describe "maintenance_plans/index", type: :view do
  before(:each) do
    assign(:maintenance_plans, [
      MaintenancePlan.create!(
        name: "Name",
        description: "Description",
        interval_km: 2,
        interval_days: 3
      ),
      MaintenancePlan.create!(
        name: "Name",
        description: "Description",
        interval_km: 2,
        interval_days: 3
      )
    ])
  end

  it "renders a list of maintenance_plans" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
