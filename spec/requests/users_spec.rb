require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let!(:chofer) { create_user(:chofer, company: company, email: "chofer@uno.cl") }

  it "asks to log in first" do
    get users_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list of the company's users" do
      get users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("chofer@uno.cl")
    end

    it "renders a user's profile" do
      get user_path(chofer)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("chofer@uno.cl")
    end

    it "renders the new form" do
      get new_user_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_user_path(chofer)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("chofer@uno.cl")
    end
  end

  it "doesn't let a chofer manage users" do
    sign_in chofer

    get users_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show a user from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get user_path(chofer)

    expect(response).to redirect_to(root_path)
  end
end
