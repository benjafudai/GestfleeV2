class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: true, foreign_key: true
      t.integer :category, default: 0, null: false
      t.decimal :amount, precision: 10, scale: 2, default: "0.0", null: false
      t.date :date, null: false
      t.string :provider
      t.text :description
      t.boolean :restricted_access, default: false, null: false

      t.timestamps
    end
  end
end
