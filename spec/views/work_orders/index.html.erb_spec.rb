require 'rails_helper'

RSpec.describe "work_orders/index", type: :view do
  before(:each) do
    assign(:work_orders, [
      WorkOrder.create!(
        vehicle_id: 2,
        maintenance_plan_id: 3,
        status: 4,
        mechanic_id: 5,
        notes: "MyText"
      ),
      WorkOrder.create!(
        vehicle_id: 2,
        maintenance_plan_id: 3,
        status: 4,
        mechanic_id: 5,
        notes: "MyText"
      )
    ])
  end

  it "renders a list of work_orders" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
