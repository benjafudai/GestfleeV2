class CreateVehicles < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicles do |t|
      t.string :plate
      t.string :brand
      t.string :model
      t.integer :year
      t.integer :status
      t.integer :odometer

      t.timestamps
    end
  end
end
