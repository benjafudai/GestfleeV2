require "rails_helper"

RSpec.describe "Weekly summary", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }

  before do
    allow(CurrencyConverter).to receive(:usd_to_clp).and_return(900)
    ActionMailer::Base.deliveries.clear
  end

  context "as the company admin" do
    before { sign_in admin }

    it "shows last week and the delivery settings" do
      get weekly_summary_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Resumen semanal", admin.email)
    end

    it "downloads the PDF" do
      get weekly_summary_path(format: :pdf)

      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("attachment", "resumen-semanal-transportes-uno-")
      expect(response.body).to start_with("%PDF")
    end

    it "saves the settings" do
      patch weekly_summary_path, params: { company: { weekly_summary_enabled: "0", weekly_summary_emails: "Gerencia@uno.cl\nconta@uno.cl" } }

      expect(response).to redirect_to(weekly_summary_path)
      company.reload
      expect(company.weekly_summary_enabled?).to be(false)
      expect(company.weekly_summary_recipients).to eq(["admin@uno.cl", "gerencia@uno.cl", "conta@uno.cl"])
    end

    it "rejects an invalid email" do
      patch weekly_summary_path, params: { company: { weekly_summary_emails: "gerencia@uno.cl, malo@" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("tiene correos no válidos: malo@")
    end

    it "sends a test to whoever asks" do
      post deliver_weekly_summary_path

      expect(response).to redirect_to(weekly_summary_path)
      expect(ActionMailer::Base.deliveries.sole.to).to eq([admin.email])
    end
  end

  %i[chofer mecanico analista].each do |role|
    it "is only for admins (not #{role})" do
      sign_in create_user(role, company: company)

      get weekly_summary_path

      expect(response).to redirect_to(root_path)
    end
  end
end
