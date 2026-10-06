require "rails_helper"

RSpec.describe ExpensesHelper, type: :helper do
  describe "#long_spanish_date" do
    it "writes the month in Spanish" do
      expect(helper.long_spanish_date(Date.new(2026, 10, 6))).to eq("6 de octubre, 2026")
      expect(helper.long_spanish_date(Date.new(2027, 1, 31))).to eq("31 de enero, 2027")
    end

    it "is empty without a date" do
      expect(helper.long_spanish_date(nil)).to eq("")
    end
  end
end
