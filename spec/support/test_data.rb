# Helpers para crear datos de prueba válidos sin depender de gemas extra.
module TestData
  PASSWORD = "Password.123456".freeze

  def create_company(name: "Empresa #{SecureRandom.hex(3)}", **attrs)
    Company.create!(
      name: name,
      rut: "#{rand(10..99)}.#{rand(100..999)}.#{rand(100..999)}-#{SecureRandom.hex(1)}",
      users_attributes: [ { email: "admin-#{SecureRandom.hex(4)}@test.cl", password: PASSWORD, role: :admin } ],
      **attrs
    )
  end

  def admin_of(company)
    company.users.find_by!(role: :admin)
  end

  def create_user(role:, company: nil, **attrs)
    User.create!(email: "#{role}-#{SecureRandom.hex(4)}@test.cl", password: PASSWORD, role: role, company: company, **attrs)
  end

  def create_vehicle(company:, **attrs)
    Vehicle.create!(company: company, plate: "AB#{SecureRandom.hex(2).upcase}", **attrs)
  end

  def create_part(company:, **attrs)
    Part.create!(company: company, sku: "SKU-#{SecureRandom.hex(3)}", name: "Filtro", unit_of_measure: "unidad", **attrs)
  end

  def pdf_upload
    { io: StringIO.new("%PDF-1.4\n%%EOF\n"), filename: "documento.pdf", content_type: "application/pdf" }
  end
end

RSpec.configure do |config|
  config.include TestData
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.after { Current.reset }
end
