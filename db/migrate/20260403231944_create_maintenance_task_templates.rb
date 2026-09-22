class CreateMaintenanceTaskTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :maintenance_task_templates do |t|
      t.references :maintenance_plan, null: false, foreign_key: true
      t.string :description
      t.integer :expected_duration_minutes
      t.integer :position

      t.timestamps
    end
  end
end
