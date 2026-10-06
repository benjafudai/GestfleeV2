require "rails_helper"

RSpec.describe "Password reset requests", type: :request do
  let(:password) { "Test-GestFlee-Spec-2026!" }

  # Company requires at least one admin on create.
  def create_company(name, rut, admin_email)
    Company.new(name: name, rut: rut).tap do |c|
      c.users.build(email: admin_email, role: :admin, password: password)
      c.save!
    end
  end

  let(:company) { create_company("Transportes Uno", "11.111.111-1", "admin@uno.cl") }
  let(:other_company) { create_company("Transportes Dos", "22.222.222-2", "admin@dos.cl") }
  let(:admin) { company.users.find_by!(role: :admin) }
  let(:superadmin) { User.create!(email: "super@gestflee.cl", password: password, role: :superadmin) }
  let(:chofer) { User.create!(email: "chofer@uno.cl", password: password, role: :chofer, company: company) }
  let!(:reset_request) { chofer.password_reset_requests.create!(status: :pending) }

  describe "as a company admin" do
    before { sign_in admin }

    it "cannot list the requests" do
      get password_reset_requests_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("No tienes permisos para acceder a esta página.")
    end

    it "cannot see a request from their own company" do
      get password_reset_request_path(reset_request)

      expect(response).to redirect_to(root_path)
    end

    it "cannot set a new password" do
      patch password_reset_request_path(reset_request),
            params: { password: "Nueva-Clave-Admin-2026!", password_confirmation: "Nueva-Clave-Admin-2026!" }

      expect(response).to redirect_to(root_path)
      expect(reset_request.reload).to be_pending
      expect(chofer.reload.valid_password?(password)).to be true
    end
  end

  describe "as a superadmin" do
    before { sign_in superadmin }

    it "lists pending requests from every company, with the company name" do
      other_chofer = User.create!(email: "chofer@dos.cl", password: password, role: :chofer, company: other_company)
      other_chofer.password_reset_requests.create!(status: :pending)

      get password_reset_requests_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("chofer@uno.cl", "Transportes Uno", "chofer@dos.cl", "Transportes Dos")
    end

    it "sets a temporary password and completes the request" do
      patch password_reset_request_path(reset_request),
            params: { password: "Clave-Temporal-2026!", password_confirmation: "Clave-Temporal-2026!" }

      expect(response).to redirect_to(password_reset_requests_path)
      expect(reset_request.reload).to be_completed
      expect(reset_request.admin).to eq(superadmin)
      expect(chofer.reload.valid_password?("Clave-Temporal-2026!")).to be true
      expect(chofer.force_password_change).to be true
    end
  end

  describe "requesting a reset from the login page" do
    it "notifies the superadmins, not the company admins" do
      superadmin
      admin

      expect {
        post user_password_path, params: { user: { email: chofer.email } }
      }.to change(PasswordResetRequest, :count).by(1)

      recipients = Notification.where(notifiable: chofer.password_reset_requests.last).map(&:user)
      expect(recipients).to eq([superadmin])
      expect(Notification.last.message).to include("chofer@uno.cl", "Transportes Uno")
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "the sidebar" do
    it "does not show the requests to a company admin" do
      sign_in admin
      get users_path

      expect(response.body).not_to include("Solicitudes de clave")
    end

    it "shows the requests to a superadmin" do
      sign_in superadmin
      get users_path

      expect(response.body).to include("Solicitudes de clave")
    end
  end
end
