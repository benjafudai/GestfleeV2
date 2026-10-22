# Entregas de productos que registra el chofer. Cada línea descuenta stock con un
# movimiento de producto; al anular la entrega, el stock se devuelve.
class CreateDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :deliveries do |t|
      t.references :company, null: false, foreign_key: true
      t.references :driver, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :vehicle, foreign_key: { on_delete: :nullify }
      t.string :customer, null: false
      t.string :address
      t.text :notes
      t.datetime :delivered_at, null: false
      t.integer :status, default: 0, null: false
      t.datetime :cancelled_at
      t.references :cancelled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :cancel_reason
      t.timestamps
    end
    add_index :deliveries, %i[company_id delivered_at]

    create_table :delivery_lines do |t|
      t.references :delivery, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 12, scale: 3, null: false
    end

    add_reference :product_movements, :delivery, foreign_key: { on_delete: :nullify }
  end
end
