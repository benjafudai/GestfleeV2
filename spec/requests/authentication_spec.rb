require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:company) { create_company }

  %w[/vehicles /notifications /alerts /users/1/user_documents/new].each do |path|
    it "sends visitors from #{path} to the login page" do
      get path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "rejects push subscriptions from visitors" do
    post push_subscriptions_path, params: { endpoint: "https://push.example/x" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "logs in with valid credentials" do
    post user_session_path, params: { user: { email: company_admin(company).email, password: TenantHelpers::SPEC_PASSWORD } }

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response).to have_http_status(:ok)
  end

  it "rejects a wrong password" do
    post user_session_path, params: { user: { email: company_admin(company).email, password: "incorrecta" } }

    expect(response).to have_http_status(:unprocessable_content)
    get vehicles_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
