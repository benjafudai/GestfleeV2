# Maquinaria se mide en horas: horómetro en el vehículo e intervalo en horas en
# el plan. El vehículo puede apuntar a un modelo de la biblioteca común.
class AddHourMeterAndVehicleModel < ActiveRecord::Migration[8.1]
  def change
    add_reference :vehicles, :vehicle_model, foreign_key: true
    add_column :vehicles, :hour_meter, :integer
    add_column :maintenance_plans, :interval_hours, :integer
  end
end
