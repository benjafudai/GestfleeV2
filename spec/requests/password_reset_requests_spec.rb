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
    # chofer already has a pending request (reset_request above); this user doesn't.
    let(:mecanico) { User.create!(email: "mecanico@uno.cl", password: password, role: :mecanico, company: company) }
    let(:same_answer) { "Si el correo está registrado, recibimos tu solicitud. El equipo de GestFlee te contactará para restablecer tu contraseña." }

    it "notifies the superadmins, not the company admins" do
      superadmin
      admin

      expect {
        post user_password_path, params: { user: { email: mecanico.email } }
      }.to change(PasswordResetRequest, :count).by(1)

      recipients = Notification.where(notifiable: mecanico.password_reset_requests.last).map(&:user)
      expect(recipients).to eq([superadmin])
      expect(Notification.last.message).to include("mecanico@uno.cl", "Transportes Uno")
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq(same_answer)
    end

    it "matches the email regardless of case and surrounding spaces" do
      mecanico

      expect {
        post user_password_path, params: { user: { email: "  Mecanico@UNO.cl " } }
      }.to change(PasswordResetRequest, :count).by(1)
    end

    it "gives the same answer for an email that isn't registered, and creates nothing" do
      superadmin

      expect {
        post user_password_path, params: { user: { email: "nadie@noexiste.cl" } }
      }.not_to change { [PasswordResetRequest.count, Notification.count] }

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq(same_answer)
    end

    it "doesn't create a second request or notify again while one is pending" do
      superadmin

      expect {
        post user_password_path, params: { user: { email: chofer.email } }
      }.not_to change { [PasswordResetRequest.count, Notification.count] }

      expect(flash[:notice]).to eq(same_answer)
    end

    it "accepts a new request once the previous one was completed" do
      reset_request.update!(status: :completed)

      expect {
        post user_password_path, params: { user: { email: chofer.email } }
      }.to change(PasswordResetRequest, :count).by(1)
    end
  end

  describe "throttling" do
    # Rack::Attack counts in Rails.cache, which is a null store in test, and
    # safelists localhost: use a real store and an outside IP.
    around do |example|
      original_store = Rack::Attack.cache.store
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rack::Attack.cache.store = original_store
    end

    def request_reset(email, ip:)
      post user_password_path, params: { user: { email: email } }, env: { "REMOTE_ADDR" => ip }
    end

    it "allows 3 reset requests per email per hour" do
      3.times { |i| request_reset(chofer.email, ip: "203.0.113.#{i + 1}") }
      expect(response).to redirect_to(new_user_session_path)

      request_reset(chofer.email, ip: "203.0.113.50")

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Demasiadas solicitudes de recuperación de contraseña")
    end

    it "allows 10 reset requests per IP per hour" do
      10.times { |i| request_reset("persona#{i}@ejemplo.cl", ip: "198.51.100.7") }
      expect(response).to redirect_to(new_user_session_path)

      request_reset("otra@ejemplo.cl", ip: "198.51.100.7")

      expect(response).to have_http_status(:too_many_requests)
    end

    it "keeps the login throttle and its own message" do
      6.times do
        post user_session_path, params: { user: { email: chofer.email, password: "incorrecta" } },
                                env: { "REMOTE_ADDR" => "192.0.2.9" }
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Demasiados intentos de inicio de sesión")
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
