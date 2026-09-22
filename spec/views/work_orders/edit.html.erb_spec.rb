require 'rails_helper'

RSpec.describe "work_orders/edit", type: :view do
  let(:work_order) {
    WorkOrder.create!(
      vehicle_id: 1,
      maintenance_plan_id: 1,
      status: 1,
      mechanic_id: 1,
      notes: "MyText"
    )
  }

  before(:each) do
    assign(:work_order, work_order)
  end

  it "renders the edit work_order form" do
    render

    assert_select "form[action=?][method=?]", work_order_path(work_order), "post" do

      assert_select "input[name=?]", "work_order[vehicle_id]"

      assert_select "input[name=?]", "work_order[maintenance_plan_id]"

      assert_select "input[name=?]", "work_order[status]"

      assert_select "input[name=?]", "work_order[mechanic_id]"

      assert_select "textarea[name=?]", "work_order[notes]"
    end
  end
end
