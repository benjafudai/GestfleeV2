# Los planes creados desde la biblioteca recuerdan de qué modelo salieron, y
# cada pauta, de qué tarea, para mostrar su paso a paso y sus repuestos.
class LinkPlansToBiblioteca < ActiveRecord::Migration[8.1]
  def change
    add_reference :maintenance_plans, :vehicle_model, foreign_key: true
    add_reference :maintenance_task_templates, :maintenance_task, foreign_key: true
  end
end
