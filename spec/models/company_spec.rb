require "rails_helper"

RSpec.describe Company, type: :model do
  it "can't be created without an admin" do
    company = Company.new(name: "Transportes Uno", rut: "11.111.111-1")

    expect(company).not_to be_valid
    expect(company.errors[:users]).to include("debe incluir al menos un administrador")
  end

  it "needs a unique RUT" do
    create_company(rut: "11.111.111-1")
    copy = Company.new(name: "Otra", rut: "11.111.111-1")
    copy.users.build(email: "admin@otra.cl", role: :admin, password: TenantHelpers::SPEC_PASSWORD)

    expect(copy).not_to be_valid
    expect(copy.errors[:rut]).to be_present
  end

  describe "#anomaly_threshold" do
    it "is 20% by default" do
      expect(create_company.anomaly_threshold).to eq(20)
    end

    it "uses the configured value" do
      company = create_company
      company.update!(fuel_anomaly_threshold: "35")

      expect(company.anomaly_threshold).to eq(35)
    end
  end

  describe "optional roles" do
    # Form checkboxes send "1"/"0" and JSON stores them as strings.
    [true, "true", "1", 1].each do |value|
      it "counts #{value.inspect} as enabled" do
        company = Company.new(has_mechanic: value, has_analyst: value, has_bodeguero: value)

        expect([company.has_mechanic?, company.has_analyst?, company.has_bodeguero?]).to all(be true)
      end
    end

    [false, "false", "0", 0, nil].each do |value|
      it "counts #{value.inspect} as disabled" do
        company = Company.new(has_mechanic: value, has_analyst: value, has_bodeguero: value)

        expect([company.has_mechanic?, company.has_analyst?, company.has_bodeguero?]).to all(be false)
      end
    end
  end

  describe "weekly summary" do
    it "is on until the company turns it off" do
      company = create_company

      expect(company.weekly_summary_enabled?).to be(true)
      company.update!(weekly_summary_enabled: "0")
      expect(company.reload.weekly_summary_enabled?).to be(false)
    end

    it "sends it to the admins and the extra emails, without repeats" do
      company = create_company
      company.update!(weekly_summary_emails: "Gerencia@uno.cl; admin@uno.cl\ngerencia@uno.cl")

      expect(company.weekly_summary_recipients).to eq(["admin@uno.cl", "gerencia@uno.cl"])
    end

    it "rejects invalid extra emails" do
      company = create_company
      company.weekly_summary_emails = "bien@uno.cl, mal@, otro"

      expect(company).not_to be_valid
      expect(company.errors[:weekly_summary_emails].first).to eq("tiene correos no válidos: mal@, otro")
    end

    it "allows up to #{Company::WEEKLY_SUMMARY_MAX_EXTRA_EMAILS} extra emails" do
      company = create_company
      company.weekly_summary_emails = Array.new(Company::WEEKLY_SUMMARY_MAX_EXTRA_EMAILS + 1) { |i| "c#{i}@uno.cl" }.join(",")

      expect(company).not_to be_valid
    end
  end
end
