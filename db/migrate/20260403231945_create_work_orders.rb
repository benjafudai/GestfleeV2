class CreateWorkOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :work_orders do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :maintenance_plan, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :start_date
      t.datetime :end_date
      t.references :mechanic, foreign_key: { to_table: :users }
      t.integer :odometer_at_maintenance
      t.text :notes

      t.timestamps
    end
  end
end
