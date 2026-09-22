class CreateSupplyRequestLines < ActiveRecord::Migration[7.1]
  def change
    create_table :supply_request_lines do |t|
      t.references :supply_request, null: false, foreign_key: true
      t.references :part, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, default: 1.0, null: false

      t.timestamps
    end
  end
end
