# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Crear usuarios de prueba
# Todos los usuarios demo usan la misma clave. Se reasigna en cada db:seed,
# así queda igual en todos los computadores aunque el usuario ya exista.
DEMO_PASSWORD = "Password.123456"

company = Company.find_or_create_by!(rut: '77.777.777-7') do |c|
  c.name = 'Empresa Principal'
  c.configuration = {has_mechanic: true, has_analyst: false}
  # Company exige al menos un usuario al crearse
  c.users.build(email: "admin@demo.cl", role: :admin, password: DEMO_PASSWORD)
end

%i[superadmin admin chofer mecanico analista].each do |role|
  user = User.find_or_initialize_by(email: "#{role}@demo.cl")
  user.role = role
  user.company = company unless role == :superadmin # No company for superadmin
  user.password = DEMO_PASSWORD
  user.save!
end

# Sprint 2: Checklist template demo
tpl = ChecklistTemplate.find_or_create_by!(name: "Inspección Diaria General", company: company) do |t|
  t.description = "Checklist obligatorio antes de iniciar operación del vehículo."
end

items_data = [
  { label: "¿Nivel de aceite motor correcto?",         item_type: :boolean, position: 0, required: true },
  { label: "¿Presión de neumáticos correcta?",         item_type: :boolean, position: 1, required: true },
  { label: "¿Luces delanteras y traseras funcionando?", item_type: :boolean, position: 2, required: true },
  { label: "Odómetro actual (km)",                     item_type: :number,  position: 3, required: true },
  { label: "Observaciones generales",                  item_type: :text,    position: 4, required: false },
]

items_data.each do |data|
  tpl.checklist_items.find_or_create_by!(label: data[:label]) do |item|
    item.item_type = data[:item_type]
    item.position  = data[:position]
    item.required  = data[:required]
  end
end