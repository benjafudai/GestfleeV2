class CreateWorkOrderPartUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :work_order_part_usages do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :part, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, default: 1.0, null: false

      t.timestamps
    end
  end
end
