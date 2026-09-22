class AddSourceToExpenses < ActiveRecord::Migration[7.1]
  def change
    add_reference :expenses, :source, polymorphic: true, null: true
  end
end
