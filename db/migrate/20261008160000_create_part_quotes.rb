class CreatePartQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :part_quotes do |t|
      t.references :company, null: false, foreign_key: true
      t.references :part, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :supplier, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.string :currency, null: false, default: "CLP"
      t.date :quoted_on, null: false
      t.string :url
      t.text :notes

      t.timestamps
    end
  end
end
