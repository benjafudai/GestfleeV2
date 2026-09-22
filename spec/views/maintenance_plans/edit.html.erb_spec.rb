require 'rails_helper'

RSpec.describe "maintenance_plans/edit", type: :view do
  let(:maintenance_plan) {
    MaintenancePlan.create!(
      name: "MyString",
      description: "MyString",
      interval_km: 1,
      interval_days: 1
    )
  }

  before(:each) do
    assign(:maintenance_plan, maintenance_plan)
  end

  it "renders the edit maintenance_plan form" do
    render

    assert_select "form[action=?][method=?]", maintenance_plan_path(maintenance_plan), "post" do

      assert_select "input[name=?]", "maintenance_plan[name]"

      assert_select "input[name=?]", "maintenance_plan[description]"

      assert_select "input[name=?]", "maintenance_plan[interval_km]"

      assert_select "input[name=?]", "maintenance_plan[interval_days]"
    end
  end
end
