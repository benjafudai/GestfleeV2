class AddCurrencyToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :expenses, :currency, :string, default: 'CLP', null: false
    add_column :parts, :currency, :string, default: 'CLP', null: false

    change_column :parts, :cost_cents, :decimal, precision: 10, scale: 2, default: 0.0, using: 'cost_cents::numeric'
    rename_column :parts, :cost_cents, :cost
  end
end
