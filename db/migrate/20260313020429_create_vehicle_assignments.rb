class CreateVehicleAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicle_assignments do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :started_on, null: false
      t.date :ended_on
      t.text :notes

      t.timestamps
    end
  end
end
