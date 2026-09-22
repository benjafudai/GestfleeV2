require 'rails_helper'

RSpec.describe "CompanySettings", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/company_settings/show"
      expect(response).to have_http_status(:success)
    end
  end

end
