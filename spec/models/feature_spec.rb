require "rails_helper"

RSpec.describe Feature do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:chofer) { create_user(:chofer, company: company) }

  def override(subject, key, enabled, expires_on: nil)
    FeatureOverride.create!(subject: subject, feature: key, enabled: enabled, expires_on: expires_on)
  end

  it "keeps every section on when the superadmin changed nothing" do
    expect(Feature.keys).to all(satisfy { |key| admin.feature?(key) })
  end

  it "turns a section off for the whole company" do
    override(company, "costos", false)

    expect(admin.feature?(:costos)).to be(false)
    expect(chofer.feature?(:costos)).to be(false)
    expect(admin.feature?(:combustible)).to be(true)
  end

  it "lets a user exception win over the company" do
    override(company, "costos", false)
    override(admin, "costos", true)
    override(chofer, "combustible", false)

    expect(admin.feature?(:costos)).to be(true)
    expect(chofer.feature?(:costos)).to be(false)
    expect(chofer.feature?(:combustible)).to be(false)
    expect(admin.feature?(:combustible)).to be(true)
  end

  it "ignores an exception after its end date" do
    override(company, "costos", false, expires_on: Date.current - 1)

    expect(admin.feature?(:costos)).to be(true)
  end

  it "always gives the superadmin every section" do
    expect(create_user(:superadmin).feature?(:costos)).to be(true)
  end

  it "rejects unknown sections" do
    expect(admin.feature?(:inventada)).to be(false)
    expect(FeatureOverride.new(subject: company, feature: "inventada", enabled: false)).not_to be_valid
  end

  it "removes the exceptions with the company and the user" do
    override(chofer, "costos", false)
    override(company, "costos", false)

    expect { chofer.destroy }.to change(FeatureOverride, :count).by(-1)
    expect { company.destroy }.to change(FeatureOverride, :count).by(-1)
  end
end
