class CreateIncidents < ActiveRecord::Migration[7.1]
  def change
    create_table :incidents do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :company, null: false, foreign_key: true
      t.integer :status
      t.integer :severity
      t.text :description

      t.timestamps
    end
  end
end
