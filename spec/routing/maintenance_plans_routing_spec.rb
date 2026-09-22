require "rails_helper"

RSpec.describe MaintenancePlansController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/maintenance_plans").to route_to("maintenance_plans#index")
    end

    it "routes to #new" do
      expect(get: "/maintenance_plans/new").to route_to("maintenance_plans#new")
    end

    it "routes to #show" do
      expect(get: "/maintenance_plans/1").to route_to("maintenance_plans#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/maintenance_plans/1/edit").to route_to("maintenance_plans#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/maintenance_plans").to route_to("maintenance_plans#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/maintenance_plans/1").to route_to("maintenance_plans#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/maintenance_plans/1").to route_to("maintenance_plans#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/maintenance_plans/1").to route_to("maintenance_plans#destroy", id: "1")
    end
  end
end
