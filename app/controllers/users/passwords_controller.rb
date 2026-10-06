class Users::PasswordsController < Devise::PasswordsController
  def create
    self.resource = resource_class.find_by(email: resource_params[:email])

    if resource
      # Create the password reset request
      reset_request = resource.password_reset_requests.create!(status: :pending)

      # Notify the GestFlee team (superadmins), who handle these requests
      company_name = resource.company&.name || "sin empresa"
      User.superadmin.find_each do |superadmin|
        Notification.create!(
          user: superadmin,
          notifiable: reset_request,
          title: "Solicitud de Recuperación de Contraseña",
          message: "El usuario #{resource.email} (#{company_name}) ha solicitado recuperar su contraseña."
        )
      end

      redirect_to new_user_session_path, notice: "Recibimos tu solicitud. El equipo de GestFlee te contactará para restablecer tu contraseña."
    else
      # Behave standard if not found to show the error
      set_flash_message(:alert, :not_found, scope: 'devise.passwords')
      redirect_to new_user_password_path
    end
  end
end
