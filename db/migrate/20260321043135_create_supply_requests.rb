class CreateSupplyRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :supply_requests do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.text :admin_notes

      t.timestamps
    end
  end
end
