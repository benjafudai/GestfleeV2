require 'rails_helper'

RSpec.describe "work_orders/new", type: :view do
  before(:each) do
    assign(:work_order, WorkOrder.new(
      vehicle_id: 1,
      maintenance_plan_id: 1,
      status: 1,
      mechanic_id: 1,
      notes: "MyText"
    ))
  end

  it "renders new work_order form" do
    render

    assert_select "form[action=?][method=?]", work_orders_path, "post" do

      assert_select "input[name=?]", "work_order[vehicle_id]"

      assert_select "input[name=?]", "work_order[maintenance_plan_id]"

      assert_select "input[name=?]", "work_order[status]"

      assert_select "input[name=?]", "work_order[mechanic_id]"

      assert_select "textarea[name=?]", "work_order[notes]"
    end
  end
end
