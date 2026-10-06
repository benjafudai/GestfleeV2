# Records most specs need. A Company can't be created without at least one
# admin (Company validates it on create), so create_company builds it with one.
module TenantHelpers
  SPEC_PASSWORD = "Test-GestFlee-Spec-2026!".freeze

  def create_company(name: "Transportes Uno", rut: "11.111.111-1", admin_email: "admin@uno.cl")
    Company.new(name: name, rut: rut).tap do |company|
      company.users.build(email: admin_email, role: :admin, password: SPEC_PASSWORD)
      company.save!
    end
  end

  def company_admin(company)
    company.users.find_by!(role: :admin)
  end

  def create_user(role, company: nil, email: nil)
    User.create!(email: email || "#{role}-#{SecureRandom.hex(3)}@test.cl",
                 password: SPEC_PASSWORD, role: role, company: company)
  end
end

RSpec.configure do |config|
  config.include TenantHelpers
end
