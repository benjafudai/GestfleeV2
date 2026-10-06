require "rails_helper"

RSpec.describe "Companies", type: :request do
  let!(:company) { create_company }
  let(:superadmin) { create_user(:superadmin) }

  it "asks to log in first" do
    get companies_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as a superadmin" do
    before { sign_in superadmin }

    it "renders the list" do
      get companies_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Transportes Uno")
    end

    it "renders the new form" do
      get new_company_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_company_path(company)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Transportes Uno")
    end
  end

  it "doesn't let a company admin manage companies" do
    sign_in company_admin(company)

    get companies_path

    expect(response).to redirect_to(root_path)
  end
end
