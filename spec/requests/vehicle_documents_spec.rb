require 'rails_helper'

RSpec.describe "VehicleDocuments", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/vehicle_documents/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/vehicle_documents/edit"
      expect(response).to have_http_status(:success)
    end
  end

end
