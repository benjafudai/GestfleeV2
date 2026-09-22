class CreateParts < ActiveRecord::Migration[7.1]
  def change
    create_table :parts do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.string :unit_of_measure, null: false
      t.decimal :stock, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :cost_cents, default: 0, null: false
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end

    add_index :parts, [:company_id, :sku], unique: true
  end
end
