require "rails_helper"

RSpec.describe "Login", type: :system do
  let(:company) { Company.create!(name: "Test Co", rut: "11.111.111-1") }
  let(:password) { "Test-GestFlee-Spec-2026!" }

  def create_user(role:, **attrs)
    User.create!(email: "#{role}@test.com", password: password, role: role, company: company, **attrs)
  end

  describe "database_authenticatable roles" do
    let!(:chofer) { create_user(role: :chofer) }

    it "logs in with correct credentials and reaches the dashboard" do
      visit new_user_session_path
      fill_in "user_email", with: chofer.email
      fill_in "user_password", with: password
      click_button "Ingresar"

      expect(page).to have_current_path(root_path)
    end

    it "rejects a wrong password with a generic message" do
      visit new_user_session_path
      fill_in "user_email", with: chofer.email
      fill_in "user_password", with: "wrong-password"
      click_button "Ingresar"

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content("inválida")
    end

    it "locks the account after 5 failed attempts" do
      visit new_user_session_path
      5.times do
        fill_in "user_email", with: chofer.email
        fill_in "user_password", with: "wrong-password"
        click_button "Ingresar"
      end

      expect(chofer.reload.access_locked?).to be true
      expect(page).to have_content("bloqueada")
    end
  end
end
