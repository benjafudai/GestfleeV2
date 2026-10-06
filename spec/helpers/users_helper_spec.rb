require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  let(:company) { create_company }
  let(:chofer) { create_user(:chofer, company: company) }
  let(:superadmin) { create_user(:superadmin) }

  describe "#role_label" do
    it "names each role in Spanish" do
      expect(helper.role_label(:mecanico)).to eq("Mecánico")
      expect(helper.role_label("superadmin")).to eq("Super Administrador")
    end

    it "falls back to a readable name for an unknown role" do
      expect(helper.role_label("jefe_de_ruta")).to eq("Jefe de ruta")
    end
  end

  describe "#account_locked_badge" do
    it "shows nothing for an active account" do
      expect(helper.account_locked_badge(chofer)).to be_nil
    end

    it "shows the badge with when the account unlocks on its own" do
      chofer.lock_access!

      badge = helper.account_locked_badge(chofer)

      expect(badge).to include("Bloqueada")
      expect(badge).to include(helper.auto_unlock_time(chofer))
    end
  end

  describe "#auto_unlock_time" do
    it "is the lock time plus Devise's unlock_in" do
      chofer.update_columns(locked_at: Time.zone.local(2026, 10, 6, 15, 0))

      expect(helper.auto_unlock_time(chofer)).to eq("06/10/2026 15:30")
    end
  end

  describe "#unlock_account_button" do
    before { chofer.lock_access! }

    it "is shown to a superadmin for a locked account" do
      allow(helper).to receive(:current_user).and_return(superadmin)

      expect(helper.unlock_account_button(chofer)).to include(helper.unlock_user_path(chofer))
    end

    it "is hidden from a company admin" do
      allow(helper).to receive(:current_user).and_return(company_admin(company))

      expect(helper.unlock_account_button(chofer)).to be_nil
    end

    it "is hidden when the account isn't locked" do
      allow(helper).to receive(:current_user).and_return(superadmin)
      chofer.unlock_access!

      expect(helper.unlock_account_button(chofer)).to be_nil
    end
  end
end
