# Biblioteca común de mantención: modelos de vehículo, tareas con su paso a
# paso, plan por modelo y repuestos por modelo y tarea. No pertenece a ninguna
# empresa; se carga con `rails biblioteca:importar`.
class CreateBiblioteca < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_models do |t|
      t.string :code, null: false
      t.string :category
      t.string :brand, null: false
      t.string :model, null: false
      t.string :configuration
      t.string :engine
      t.string :fuel
      t.string :meter_unit, null: false, default: "km"
      t.integer :base_interval
      t.text :typical_use

      t.timestamps
    end
    add_index :vehicle_models, :code, unique: true

    create_table :maintenance_tasks do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :system
      t.string :applies_to
      t.decimal :estimated_hours, precision: 5, scale: 2
      t.text :tools
      t.text :ppe

      t.timestamps
    end
    add_index :maintenance_tasks, :code, unique: true

    create_table :maintenance_task_steps do |t|
      t.references :maintenance_task, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :description, null: false

      t.timestamps
    end
    add_index :maintenance_task_steps, [:maintenance_task_id, :position], unique: true

    create_table :vehicle_model_plan_items do |t|
      t.string :code, null: false
      t.references :vehicle_model, null: false, foreign_key: true
      t.references :maintenance_task, null: false, foreign_key: true
      t.string :action
      t.integer :frequency_value, null: false
      t.string :frequency_unit, null: false
      t.integer :frequency_months
      t.text :note

      t.timestamps
    end
    add_index :vehicle_model_plan_items, :code, unique: true

    create_table :vehicle_model_parts do |t|
      t.string :code, null: false
      t.references :vehicle_model, null: false, foreign_key: true
      t.references :maintenance_task, null: false, foreign_key: true
      t.string :description, null: false
      t.string :specification
      t.string :oem_code
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 0
      t.string :unit
      t.integer :unit_price_net_clp
      t.string :price_type

      t.timestamps
    end
    add_index :vehicle_model_parts, :code, unique: true
  end
end
