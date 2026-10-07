# Records for specs that need more than one company or a working fleet.
# create_company (TenantHelpers) uses a fixed RUT and admin email, so a second
# company needs its own.
module FleetHelpers
  def create_other_company(name: "Empresa #{SecureRandom.hex(3)}")
    create_company(name: name, rut: "#{SecureRandom.hex(4)}-K", admin_email: "admin-#{SecureRandom.hex(4)}@test.cl")
  end

  # Turns on the optional modules (has_mechanic, has_analyst) of a company.
  def with_modules(company, **modules)
    company.update!(**modules)
    company
  end

  def create_part(company:, **attrs)
    Part.unscoped.create!(company: company, sku: "SKU-#{SecureRandom.hex(3)}", name: "Filtro", unit_of_measure: "unidad", **attrs)
  end

  def assign_vehicle(driver, vehicle)
    VehicleAssignment.create!(user: driver, vehicle: vehicle, started_on: Date.current)
  end

  # A file as the browser sends it in a form, from a FileHelpers attachable.
  def uploaded(attachable)
    Rack::Test::UploadedFile.new(attachable[:io], attachable[:content_type], original_filename: attachable[:filename])
  end
end

RSpec.configure do |config|
  config.include FleetHelpers
  config.after { Current.reset }
end
