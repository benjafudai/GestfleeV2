class CreateVehicleDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicle_documents do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.integer :doc_type
      t.date :due_on
      t.text :notes
      t.integer :status

      t.timestamps
    end
  end
end
