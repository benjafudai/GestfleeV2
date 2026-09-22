class CreatePartFitments < ActiveRecord::Migration[7.1]
  def change
    create_table :part_fitments do |t|
      t.references :part, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true

      t.timestamps
    end
    add_index :part_fitments, [:part_id, :vehicle_id], unique: true
  end
end
