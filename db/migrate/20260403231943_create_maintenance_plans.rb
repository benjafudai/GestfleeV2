class CreateMaintenancePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :maintenance_plans do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :interval_km
      t.integer :interval_days

      t.timestamps
    end
  end
end
