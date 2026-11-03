require "rails_helper"

RSpec.describe "Company features panel", type: :request do
  let!(:company) { create_company }
  let(:admin) { company_admin(company) }
  let(:superadmin) { create_user(:superadmin) }
  let(:chofer) { create_user(:chofer, company: company) }

  describe "the panel" do
    it "is only for the superadmin" do
      sign_in admin
      get edit_company_features_path(company)
      expect(response).to redirect_to(root_path)

      patch company_features_path(company), params: { features: { company: { costos: "off" } } }
      expect(FeatureOverride.count).to eq(0)
    end

    it "shows every section and the company users" do
      chofer
      sign_in superadmin
      get edit_company_features_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Funciones de Transportes Uno", "Análisis de fallas", chofer.email)
    end

    it "is linked from the companies list" do
      sign_in superadmin
      get companies_path

      expect(response.body).to include(edit_company_features_path(company))
    end

    it "turns sections off for the company and back on" do
      sign_in superadmin
      patch company_features_path(company), params: { features: { company: { costos: "off", combustible: "on" } } }

      expect(response).to redirect_to(edit_company_features_path(company))
      expect(FeatureOverride.where(subject: company).pluck(:feature, :enabled)).to eq([["costos", false]])
      expect(FeatureOverride.last.granted_by).to eq(superadmin)

      patch company_features_path(company), params: { features: { company: { costos: "on" } } }
      expect(FeatureOverride.count).to eq(0)
    end

    it "saves exceptions per user and clears them with 'same as company'" do
      sign_in superadmin
      patch company_features_path(company), params: { features: { users: { chofer.id => { combustible: "off", costos: "company" } } } }

      expect(chofer.reload.feature?(:combustible)).to be(false)
      expect(admin.feature?(:combustible)).to be(true)

      patch company_features_path(company), params: { features: { users: { chofer.id => { combustible: "company" } } } }
      expect(FeatureOverride.count).to eq(0)
    end

    it "does not touch users of another company" do
      other = create_company(name: "Otra", rut: "22.222.222-2", admin_email: "admin@otra.cl")
      sign_in superadmin
      patch company_features_path(company), params: { features: { users: { company_admin(other).id => { costos: "off" } } } }

      expect(FeatureOverride.count).to eq(0)
    end

    it "ignores unknown sections" do
      sign_in superadmin
      patch company_features_path(company), params: { features: { company: { inventada: "off" } } }

      expect(FeatureOverride.count).to eq(0)
    end
  end

  describe "a section turned off" do
    before { FeatureOverride.create!(subject: company, feature: "costos", enabled: false) }

    it "disappears from the menu and the dashboard" do
      sign_in admin
      get dashboard_path

      expect(response.body).not_to include(expenses_path)
      expect(response.body).to include(fuel_fills_path)
    end

    it "is blocked by URL" do
      sign_in admin
      get expenses_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Costos")
    end

    it "keeps working for a user with an exception" do
      FeatureOverride.create!(subject: admin, feature: "costos", enabled: true)
      sign_in admin
      get expenses_path

      expect(response).to have_http_status(:ok)
    end

    it "stays visible to the superadmin" do
      sign_in superadmin
      get expenses_path

      expect(response).to have_http_status(:ok)
    end
  end

  it "hides fuel for a single driver only" do
    FeatureOverride.create!(subject: chofer, feature: "combustible", enabled: false)
    sign_in chofer
    get fuel_fills_path
    expect(response).to redirect_to(root_path)

    sign_in admin
    get fuel_fills_path
    expect(response).to have_http_status(:ok)
  end

  it "skips the weekly summary email when that section is off" do
    FeatureOverride.create!(subject: company, feature: "resumen_semanal", enabled: false)
    result = WeeklySummarySender.new(today: Date.current, logger: Logger.new(nil)).call

    expect(result.skipped).to include(company.name)
    expect(result.sent).not_to include(company.name)
  end
end
