require 'rails_helper'

RSpec.describe "expenses/show", type: :view do
  before(:each) do
    assign(:expense, Expense.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
