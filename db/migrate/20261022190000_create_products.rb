# Inventario de lo que vende cada empresa (carne, cajas, sacos...), aparte de los
# repuestos del taller. El stock solo cambia con movimientos, que quedan de historial.
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code
      t.string :category
      t.string :unit, null: false
      t.decimal :stock, precision: 12, scale: 3, default: 0, null: false
      t.decimal :min_stock, precision: 12, scale: 3
      t.decimal :price, precision: 12, scale: 2
      t.string :currency, default: "CLP", null: false
      t.text :notes
      t.timestamps
    end
    add_index :products, %i[company_id code], unique: true, where: "code IS NOT NULL"
    add_index :products, %i[company_id name]

    create_table :product_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, foreign_key: { on_delete: :nullify }
      t.integer :kind, null: false
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :stock_after, precision: 12, scale: 3, null: false
      t.string :note
      t.datetime :created_at, null: false
    end
  end
end
