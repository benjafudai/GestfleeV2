require 'rails_helper'

RSpec.describe "maintenance_plans/new", type: :view do
  before(:each) do
    assign(:maintenance_plan, MaintenancePlan.new(
      name: "MyString",
      description: "MyString",
      interval_km: 1,
      interval_days: 1
    ))
  end

  it "renders new maintenance_plan form" do
    render

    assert_select "form[action=?][method=?]", maintenance_plans_path, "post" do

      assert_select "input[name=?]", "maintenance_plan[name]"

      assert_select "input[name=?]", "maintenance_plan[description]"

      assert_select "input[name=?]", "maintenance_plan[interval_km]"

      assert_select "input[name=?]", "maintenance_plan[interval_days]"
    end
  end
end
