require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:company) { create_company }

  it "asks to log in first" do
    get root_path

    expect(response).to redirect_to(new_user_session_path)
  end

  # Each role gets its own dashboard; every one of them has to render.
  %i[admin chofer mecanico analista bodeguero].each do |role|
    it "renders for the #{role}" do
      user = role == :admin ? company_admin(company) : create_user(role, company: company)
      sign_in user

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  it "renders for a superadmin" do
    sign_in create_user(:superadmin)

    get dashboard_path

    expect(response).to have_http_status(:ok)
  end
end
