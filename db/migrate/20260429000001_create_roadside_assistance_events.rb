class CreateRoadsideAssistanceEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :roadside_assistance_events do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.text :description
      t.datetime :timestamp

      t.timestamps
    end
  end
end
