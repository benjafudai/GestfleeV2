class CreateWorkOrderTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :work_order_tasks do |t|
      t.references :work_order, null: false, foreign_key: true
      t.string :description, null: false
      t.boolean :completed, default: false, null: false

      t.timestamps
    end
  end
end
