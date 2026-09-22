class CreateFuelFills < ActiveRecord::Migration[7.1]
  def change
    create_table :fuel_fills do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.decimal :liters, precision: 10, scale: 2, null: false
      t.decimal :cost, precision: 10, scale: 2, null: false
      t.string :currency, default: "CLP", null: false
      t.integer :odometer, null: false
      t.date :date, null: false
      t.text :notes
      t.decimal :km_per_liter, precision: 10, scale: 2

      t.timestamps
    end
  end
end
