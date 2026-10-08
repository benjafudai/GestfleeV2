# Una biblioteca chica para specs: un modelo, dos tareas con pasos, tres
# líneas de plan (dos cada 10.000 km o 6 meses y una diaria) y dos repuestos.
module BibliotecaHelpers
  def create_small_biblioteca
    hilux = VehicleModel.create!(code: "CTA-01", category: "Camioneta", brand: "Toyota", model: "Hilux", meter_unit: "km")
    oil = MaintenanceTask.create!(code: "TR-01", name: "Cambio de aceite de motor y filtro", estimated_hours: 0.8,
                                  tools: "Llave de filtro", ppe: "Guantes nitrilo")
    oil.steps.create!(position: 1, description: "Calentar el motor y apagarlo")
    oil.steps.create!(position: 2, description: "Retirar el tapón de drenaje")
    daily = MaintenanceTask.create!(code: "TR-23", name: "Inspección diaria del operador")
    filter = MaintenanceTask.create!(code: "TR-02", name: "Reemplazo de filtro de aire")

    hilux.plan_items.create!(code: "CTA-01-TR-01", maintenance_task: oil, action: "Reemplazar", frequency_value: 10_000, frequency_unit: "km", frequency_months: 6)
    hilux.plan_items.create!(code: "CTA-01-TR-02", maintenance_task: filter, action: "Reemplazar", frequency_value: 10_000, frequency_unit: "km", frequency_months: 6)
    hilux.plan_items.create!(code: "CTA-01-TR-23", maintenance_task: daily, action: "Inspeccionar", frequency_value: 1, frequency_unit: "dias")

    hilux.parts.create!(code: "CTA-01-R01", maintenance_task: oil, description: "Aceite de motor", specification: "5W-30",
                        quantity: 7.5, unit: "L", unit_price_net_clp: 5_000, price_type: "verificado")
    hilux.parts.create!(code: "CTA-01-R02", maintenance_task: oil, description: "Filtro de aceite",
                        quantity: 1, unit: "un", unit_price_net_clp: 8_000, price_type: "estimado")
    hilux
  end
end

RSpec.configure do |config|
  config.include BibliotecaHelpers
end
