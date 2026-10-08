class Users::PasswordsController < Devise::PasswordsController
  # Same answer whether the email has an account or not, so this form can't be
  # used to find out which emails are registered. Throttled in rack_attack.rb.
  def create
    email = resource_params[:email].to_s.strip.downcase
    user = resource_class.find_by(email: email)

    request_reset_for(user) if user

    redirect_to new_user_session_path, notice: "Si el correo está registrado, recibimos tu solicitud. El equipo de GestFlee te contactará para restablecer tu contraseña."
  end

  private

  # One pending request per user: asking again while one is still waiting
  # doesn't create another one or notify the team again.
  def request_reset_for(user)
    return if user.password_reset_requests.pending.exists?

    reset_request = user.password_reset_requests.create!(status: :pending)

    # Notify the GestFlee team (superadmins), who handle these requests
    company_name = user.company&.name || "sin empresa"
    User.superadmin.find_each do |superadmin|
      Notification.create!(
        user: superadmin,
        notifiable: reset_request,
        title: "Solicitud de Recuperación de Contraseña",
        message: "El usuario #{user.email} (#{company_name}) ha solicitado recuperar su contraseña."
      )
    end
  end
end
