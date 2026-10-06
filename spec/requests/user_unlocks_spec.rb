require "rails_helper"

RSpec.describe "Unlocking a locked account", type: :request do
  let(:password) { "Test-GestFlee-Spec-2026!" }

  # Company requires at least one admin on create.
  let(:company) do
    Company.new(name: "Transportes Uno", rut: "11.111.111-1").tap do |c|
      c.users.build(email: "admin@uno.cl", role: :admin, password: password)
      c.save!
    end
  end
  let(:admin) { company.users.find_by!(role: :admin) }
  let(:superadmin) { User.create!(email: "super@gestflee.cl", password: password, role: :superadmin) }
  let(:chofer) { User.create!(email: "chofer@uno.cl", password: password, role: :chofer, company: company) }

  before { chofer.lock_access! }

  describe "as a superadmin" do
    before { sign_in superadmin }

    it "unlocks the account and clears the failed attempts" do
      chofer.update_columns(failed_attempts: 5)

      patch unlock_user_path(chofer)

      expect(response).to redirect_to(user_path(chofer))
      expect(flash[:notice]).to eq("La cuenta de chofer@uno.cl fue desbloqueada.")
      chofer.reload
      expect(chofer.access_locked?).to be false
      expect(chofer.failed_attempts).to eq(0)
    end

    it "says so when the account wasn't locked" do
      chofer.unlock_access!

      patch unlock_user_path(chofer)

      expect(flash[:notice]).to eq("La cuenta de chofer@uno.cl no estaba bloqueada.")
    end

    it "shows the locked badge and the unlock button on the user list and profile" do
      get users_path
      expect(response.body).to include("Bloqueada", unlock_user_path(chofer))

      get user_path(chofer)
      expect(response.body).to include("se desbloquea sola el", "Desbloquear cuenta")
    end

    it "warns about the lock on the password reset request" do
      reset_request = chofer.password_reset_requests.create!(status: :pending)

      get password_reset_request_path(reset_request)

      expect(response.body).to include("La cuenta está bloqueada", unlock_user_path(chofer))
    end

    it "lets the user log in right after unlocking with the temporary password" do
      reset_request = chofer.password_reset_requests.create!(status: :pending)
      patch password_reset_request_path(reset_request),
            params: { password: "Clave-Temporal-2026!", password_confirmation: "Clave-Temporal-2026!" }
      patch unlock_user_path(chofer)
      sign_out superadmin

      post user_session_path, params: { user: { email: chofer.email, password: "Clave-Temporal-2026!" } }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "as a company admin" do
    before { sign_in admin }

    it "cannot unlock the account" do
      patch unlock_user_path(chofer)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acceso denegado")
      expect(chofer.reload.access_locked?).to be true
    end

    it "sees that the account is locked, but not the unlock button" do
      get users_path

      expect(response.body).to include("Bloqueada")
      expect(response.body).not_to include(unlock_user_path(chofer))
    end
  end

  it "a chofer cannot unlock anyone" do
    other = User.create!(email: "otro@uno.cl", password: password, role: :chofer, company: company)
    sign_in other

    patch unlock_user_path(chofer)

    expect(response).to redirect_to(root_path)
    expect(chofer.reload.access_locked?).to be true
  end
end
