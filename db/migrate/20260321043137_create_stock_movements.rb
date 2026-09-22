class CreateStockMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :stock_movements do |t|
      t.references :part, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.integer :movement_type, null: false
      t.string :reference

      t.timestamps
    end
  end
end
