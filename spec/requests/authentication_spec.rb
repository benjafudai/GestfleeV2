require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let(:company) { create_company }

  it 'sends visitors to the login page' do
    get vehicles_path
    expect(response).to redirect_to(new_user_session_path)
  end

  %w[/notifications /alerts /users/1/user_documents/new].each do |path|
    it "sends visitors from #{path} to the login page" do
      get path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it 'rejects push subscriptions from visitors' do
    post push_subscriptions_path, params: { endpoint: 'https://push.example/x' }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'logs in with valid credentials' do
    admin = admin_of(company)
    post user_session_path, params: { user: { email: admin.email, password: TestData::PASSWORD } }

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response).to have_http_status(:ok)
  end

  it 'rejects a wrong password' do
    post user_session_path, params: { user: { email: admin_of(company).email, password: 'incorrecta' } }

    expect(response).to have_http_status(:unprocessable_content)
    get vehicles_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'forces a password change before anything else when flagged' do
    user = create_user(role: :chofer, company: company, force_password_change: true)
    sign_in user

    get dashboard_path
    expect(response).to redirect_to(edit_user_force_password_change_path(user))
  end
end
