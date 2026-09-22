require 'rails_helper'

RSpec.describe "work_orders/show", type: :view do
  before(:each) do
    assign(:work_order, WorkOrder.create!(
      vehicle_id: 2,
      maintenance_plan_id: 3,
      status: 4,
      mechanic_id: 5,
      notes: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/MyText/)
  end
end
